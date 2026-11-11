import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
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

  final sampleProductPao = Product(
    id: 'prod-2',
    canonicalName: 'Pão Francês',
    categoryId: 'padaria',
    defaultUnit: Unit.kg,
    createdAt: DateTime(2026, 9, 21),
    updatedAt: DateTime(2026, 9, 21),
  );

  final sampleDraft = ReceiptDraft(
    store: const StoreDraft(
      name: 'Carrefour Hipermercado',
      cnpj: '45.543.915/0001-81',
      isCnpjValid: true,
    ),
    purchasedAt: DateTime(2026, 9, 21, 14, 30),
    accessKey: '35260945543915000181650010000123451000123456',
    items: [
      ReceiptItemDraft(
        rawDescription: 'ARROZ AGULH 5KG',
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
      ReceiptItemDraft(
        rawDescription: 'PAO FRANC 50G',
        quantity: const Quantity(500, Unit.g),
        unitPrice: const Money(1200),
        totalPrice: const Money(600),
        confidence: 0.90,
        selected: true,
        match: ProductMatch(
          product: sampleProductPao,
          origin: const ExactSeedAlias(),
          score: 1.0,
        ),
      ),
      ReceiptItemDraft(
        rawDescription: 'MANTEIGA EXTRA 200G',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(1290),
        totalPrice: const Money(1290),
        confidence: 0.45, // CA-3.1: unselected by default
        selected: false,
      ),
    ],
    subtotal: const Money(4390),
    discount: const Money(0),
    total: const Money(
      8740,
    ), // CA-4.1: divergence of R$ 3.00 relative to selected items sum R$ 31.00
    confidence: 0.85,
  );

  testWidgets('OcrReviewScreen golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OcrReviewScreen(draft: sampleDraft),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OcrReviewScreen),
      matchesGoldenFile('ocr_review_screen.png'),
    );
  });

  testWidgets(
    'CA-3.1 - Item with confidence 0.45 appears unselected and highlighted with check this item',
    (tester) async {
      final draftLowConf = ReceiptDraft(
        store: const StoreDraft(name: 'Mercado Teste'),
        items: [
          ReceiptItemDraft(
            rawDescription: 'AÇÚCAR REFINADO 1KG',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(450),
            totalPrice: const Money(450),
            confidence: 0.45,
          ),
        ],
        total: const Money(450),
        confidence: 0.45,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: draftLowConf),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que o item aparece na tela
      expect(find.text('AÇÚCAR REFINADO 1KG'), findsOneWidget);

      // Verify low confidence highlight message is visible (CA-3.1, A11Y-5)
      expect(find.text('confira este item'), findsOneWidget);

      // Verifica o estado da Checkbox (desmarcada)
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    },
  );

  testWidgets(
    'CA-3.2 - Read text PAO FRANC 50G displays detected as PAO FRANC 50G and match source',
    (tester) async {
      final draftMatched = ReceiptDraft(
        store: const StoreDraft(name: 'Padaria Fictícia'),
        items: [
          ReceiptItemDraft(
            rawDescription: 'PAO FRANC 50G',
            quantity: const Quantity(500, Unit.g),
            unitPrice: const Money(1200),
            totalPrice: const Money(600),
            confidence: 0.90,
            selected: true,
            match: ProductMatch(
              product: sampleProductPao,
              origin: const ExactSeedAlias(),
              score: 1.0,
            ),
          ),
        ],
        total: const Money(600),
        confidence: 0.90,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: draftMatched),
        ),
      );
      await tester.pumpAndSettle();

      // Nome do produto vinculado
      expect(find.text('Pão Francês'), findsOneWidget);

      // Texto lido explicitamente (CA-3.2)
      expect(find.text('detectado como PAO FRANC 50G'), findsOneWidget);

      // Link origin (RN-197)
      expect(find.textContaining('Vínculo: semente'), findsOneWidget);
    },
  );

  testWidgets(
    'CA-4.1 - Items sum differs from total: displays divergence and asks confirmation when saving',
    (tester) async {
      ReceiptDraft? savedDraft;

      final draftDivergence = ReceiptDraft(
        store: const StoreDraft(name: 'Mercado Divergência'),
        items: [
          ReceiptItemDraft(
            rawDescription: 'PRODUTO A',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(8440),
            totalPrice: const Money(8440),
            confidence: 0.95,
            selected: true,
          ),
        ],
        total: const Money(
          8740,
        ), // itemsSum = 84.40 | total = 87.40 -> divergence of R$ 3.00
        confidence: 0.95,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: draftDivergence,
            onSave: (draft) => savedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify divergence warning is displayed on screen (CA-4.1)
      expect(find.textContaining('Divergência de R\$ 3,00'), findsOneWidget);

      // Tap Save button
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog opened requesting confirmation (CA-4.1)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Divergência no total'), findsOneWidget);
      expect(find.textContaining('Deseja salvar assim mesmo?'), findsOneWidget);
      expect(savedDraft, isNull);

      // Tap "Save" in confirmation dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Salvar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify onSave callback was invoked with draft
      expect(savedDraft, equals(draftDivergence));
    },
  );

  testWidgets('RN-194 - Invalid CNPJ displays unconfirmed CNPJ warning', (
    tester,
  ) async {
    final draftInvalidCnpj = ReceiptDraft(
      store: const StoreDraft(
        name: 'Loja Desconhecida',
        cnpj: '11.111.111/1111-11',
        rawCnpj: '11111111111111',
        isCnpjValid: false, // RN-194: invalid CNPJ
      ),
      items: [],
      total: const Money(0),
      confidence: 0.90,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OcrReviewScreen(draft: draftInvalidCnpj),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of "CNPJ unconfirmed" tag
    expect(find.text('CNPJ não confirmado'), findsOneWidget);
  });

  testWidgets(
    'A11Y-2 - Tap target of elements meets androidTapTargetGuideline (>=48dp)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: sampleDraft),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    },
  );

  testWidgets(
    'T-V5 / A11Y-3 - Screen reader has semantic action labels for items and buttons',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: sampleDraft),
        ),
      );
      await tester.pumpAndSettle();

      // Verify complete semantic label of selected item (A11Y-3)
      expect(
        find.bySemanticsLabel(
          'Arroz Agulhinha 5kg, detectado como ARROZ AGULH 5KG, 1 un, R\$ 25,00, selecionado',
        ),
        findsOneWidget,
      );

      // Label test for unselected item with low confidence (A11Y-3, A11Y-5)
      final draftLowConf = ReceiptDraft(
        store: const StoreDraft(name: 'Mercado Teste'),
        items: [
          ReceiptItemDraft(
            rawDescription: 'MANTEIGA EXTRA 200G',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(1290),
            totalPrice: const Money(1290),
            confidence: 0.45,
            selected: false,
          ),
        ],
        total: const Money(1290),
        confidence: 0.45,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: draftLowConf),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'MANTEIGA EXTRA 200G.*1 un.*R\$ 12,90.*confira este item.*desmarcado',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'T-V5 / A11Y-5 - Divergence, low confidence, and CNPJ warnings have text + icon without relying solely on color',
    (tester) async {
      final draftAlerts = ReceiptDraft(
        store: const StoreDraft(
          name: 'Loja Alerta',
          cnpj: '11.111.111/1111-11',
          isCnpjValid: false,
        ),
        items: [
          ReceiptItemDraft(
            rawDescription: 'ITEM FRACO',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(1000),
            totalPrice: const Money(1000),
            confidence: 0.40,
            selected: false,
          ),
        ],
        total: const Money(1500), // Divergence of R$ 5.00
        confidence: 0.40,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(draft: draftAlerts),
        ),
      );
      await tester.pumpAndSettle();

      // All warnings must have explicit text beyond color styles (A11Y-5)
      expect(find.text('CNPJ não confirmado'), findsOneWidget);
      expect(find.text('Divergência no valor total'), findsOneWidget);
      expect(find.text('confira este item'), findsOneWidget);

      // Visual warning icons present (CNPJ badge, divergence, low confidence banner, item tile)
      expect(find.byIcon(AppIcons.qualityWarning), findsNWidgets(4));
    },
  );
}
