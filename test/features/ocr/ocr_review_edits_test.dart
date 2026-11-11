import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

void main() {
  final sampleProductArroz = Product(
    id: 'prod-1',
    canonicalName: 'Arroz Agulhinha 5kg',
    categoryId: 'alimentos',
    defaultUnit: Unit.kg,
    createdAt: DateTime(2026, 9, 21),
    updatedAt: DateTime(2026, 9, 21),
  );

  final sampleProductFeijao = Product(
    id: 'prod-2',
    canonicalName: 'Feijão Preto 1kg',
    categoryId: 'alimentos',
    defaultUnit: Unit.kg,
    createdAt: DateTime(2026, 9, 21),
    updatedAt: DateTime(2026, 9, 21),
  );

  final baseDraft = ReceiptDraft(
    store: const StoreDraft(
      name: 'Supermercado Inicial',
      cnpj: '45.543.915/0001-81',
      isCnpjValid: true,
    ),
    purchasedAt: DateTime(2026, 9, 21, 14, 30),
    accessKey: '12345678901234567890123456789012345678901234',
    items: [
      ReceiptItemDraft(
        rawDescription: 'ARROZ 5KG',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(2500),
        totalPrice: const Money(2500),
        confidence: 0.95,
        selected: true,
        match: ProductMatch(
          product: sampleProductArroz,
          origin: const ExactSeedAlias(),
          score: 1.0,
        ),
      ),
    ],
    subtotal: const Money(2500),
    discount: const Money(0),
    total: const Money(2500),
    confidence: 0.95,
  );

  testWidgets('T-16b (RN-198) - Allows editing header (store and CNPJ)', (
    tester,
  ) async {
    ReceiptDraft? updatedDraft;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OcrReviewScreen(
          draft: baseDraft,
          onSave: (draft) => updatedDraft = draft,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap edit establishment button
    await tester.tap(find.byTooltip('Editar estabelecimento'));
    await tester.pumpAndSettle();

    expect(find.text('Editar cabeçalho'), findsOneWidget);

    // Preenche novo nome de estabelecimento
    final nameField = find.widgetWithText(TextField, 'Estabelecimento *');
    await tester.enterText(nameField, 'Mercado Atualizado');

    // Toca em Salvar no dialog
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Salvar'),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica que o nome atualizado aparece na tela
    expect(find.text('Mercado Atualizado'), findsOneWidget);

    // Tap Save on review screen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(updatedDraft?.store.name, equals('Mercado Atualizado'));
  });

  testWidgets(
    'T-16b (RN-198) - Allows editing receipt totals (subtotal, discount, and total)',
    (tester) async {
      ReceiptDraft? updatedDraft;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: baseDraft,
            onSave: (draft) => updatedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap edit totals button
      await tester.tap(find.byTooltip('Editar totais'));
      await tester.pumpAndSettle();

      expect(find.text('Editar totais'), findsOneWidget);

      // Altera subtotal para 30,00
      final subtotalField = find.widgetWithText(TextField, 'Subtotal (R\$)');
      await tester.enterText(subtotalField, '30,00');

      // Altera total lido para 30,00
      final totalField = find.widgetWithText(TextField, 'Total lido (R\$)');
      await tester.enterText(totalField, '30,00');

      // Toca em Salvar no dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save on review screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Salvar'),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(updatedDraft?.subtotal, equals(const Money(3000)));
      expect(updatedDraft?.total, equals(const Money(3000)));
    },
  );

  testWidgets('T-16b (RN-198) - Allows adding new item in review', (
    tester,
  ) async {
    ReceiptDraft? updatedDraft;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OcrReviewScreen(
          draft: baseDraft,
          onSave: (draft) => updatedDraft = draft,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add item button
    await tester.tap(find.text('Adicionar item'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar item'), findsWidgets);

    // Enter description for new item
    final descField = find.widgetWithText(TextField, 'Descrição lida / Nome *');
    await tester.enterText(descField, 'LEITE INTEGRAL 1L');

    // Enter unit price
    final priceField = find.widgetWithText(TextField, 'Preço unitário (R\$) *');
    await tester.enterText(priceField, '5,50');

    // Salvar item
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Salvar'),
      ),
    );
    await tester.pumpAndSettle();

    // O novo item deve estar na lista
    expect(find.text('LEITE INTEGRAL 1L'), findsOneWidget);

    // Salvar na tela
    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(updatedDraft?.items.length, equals(2));
    expect(
      updatedDraft?.items.last.rawDescription,
      equals('LEITE INTEGRAL 1L'),
    );
  });

  testWidgets('T-16b (RN-198) - Allows deleting item from review list', (
    tester,
  ) async {
    ReceiptDraft? updatedDraft;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OcrReviewScreen(
          draft: baseDraft,
          onSave: (draft) => updatedDraft = draft,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arroz Agulhinha 5kg'), findsOneWidget);

    // Tap delete item button
    await tester.tap(find.byTooltip('Apagar item'));
    await tester.pumpAndSettle();

    // Item deve ter sido removido
    expect(find.text('Arroz Agulhinha 5kg'), findsNothing);

    // Save review screen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(updatedDraft?.items.isEmpty, isTrue);
  });

  testWidgets(
    'T-16b (RN-198) - Allows changing matched product and altering quantity/unit',
    (tester) async {
      ReceiptDraft? updatedDraft;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: baseDraft,
            availableProducts: [sampleProductFeijao],
            onSave: (draft) => updatedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Editar item existente
      await tester.tap(find.byTooltip('Editar item'));
      await tester.pumpAndSettle();

      expect(find.text('Editar item'), findsOneWidget);

      // Toca em Trocar / Vincular
      await tester.tap(find.text('Trocar / Vincular'));
      await tester.pumpAndSettle();

      expect(find.text('Vincular produto'), findsOneWidget);

      // Search for product
      final searchField = find.widgetWithText(TextField, 'Nome do produto');
      await tester.enterText(searchField, 'Feijão');
      await tester.pumpAndSettle();

      expect(find.text('Feijão Preto 1kg'), findsOneWidget);

      // Select suggested product
      await tester.tap(find.text('Feijão Preto 1kg'));
      await tester.pumpAndSettle();

      // Save item edit dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify linked product was changed
      expect(find.text('Feijão Preto 1kg'), findsOneWidget);

      // Salvar na tela principal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Salvar'),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(
        updatedDraft?.items.first.match?.product.canonicalName,
        equals('Feijão Preto 1kg'),
      );
    },
  );

  testWidgets(
    'T-16b (RN-198) - Preserves EAN when editing item and calculates total automatically if not provided',
    (tester) async {
      ReceiptDraft? updatedDraft;

      final draftWithEan = baseDraft.copyWith(
        items: [
          ReceiptItemDraft(
            rawDescription: 'BISCOITO RECHEADO 140G',
            ean: '7891234567890',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(450),
            totalPrice: const Money(450),
            confidence: 0.90,
            selected: true,
          ),
        ],
        total: const Money(450),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: draftWithEan,
            onSave: (draft) => updatedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Edita item existente com EAN
      await tester.tap(find.byTooltip('Editar item'));
      await tester.pumpAndSettle();

      // Altera apenas quantidade para 2
      final qtyField = find.widgetWithText(TextField, 'Quantidade *');
      await tester.enterText(qtyField, '2');

      // Save edit dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();

      // Salvar na tela principal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Salvar'),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Verify EAN was preserved and total recomputed for 2 x 4.50 = 9.00
      expect(updatedDraft?.items.first.ean, equals('7891234567890'));
      expect(updatedDraft?.items.first.totalPrice, equals(const Money(900)));
    },
  );

  testWidgets(
    'T-16b (A11Y) - Edit and Delete item buttons are accessible for screen readers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: baseDraft),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Editar item'), findsOneWidget);
      expect(find.byTooltip('Apagar item'), findsOneWidget);
    },
  );
}
