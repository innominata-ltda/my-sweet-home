import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

void main() {
  final sampleDraft = ReceiptDraft(
    store: const StoreDraft(
      name: 'Supermercado Central',
      cnpj: '45.543.915/0001-81',
      isCnpjValid: true,
    ),
    purchasedAt: DateTime(2026, 10, 16, 10, 0),
    items: List.generate(
      15,
      (i) => ReceiptItemDraft(
        rawDescription: 'Item ${i + 1}',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(1000),
        totalPrice: const Money(1000),
        confidence: 0.95,
        selected: true,
      ),
    ),
    subtotal: const Money(15000),
    discount: const Money(0),
    total: const Money(15000),
    confidence: 0.95,
  );

  Widget buildSubject({
    ReceiptDraft? draft,
    ScrollController? scrollController,
    List<Product>? availableProducts,
    ValueChanged<ReceiptDraft>? onSave,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OcrReviewScreen(
        draft: draft ?? sampleDraft,
        scrollController: scrollController,
        availableProducts: availableProducts,
        onSave: onSave,
      ),
    );
  }

  group('OcrReviewScreen — Primary ScrollController (RF-044, CA-3.1, T-B09)', () {
    testWidgets(
      'configures ListView with primary = true by default to support scroll capture',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        final listView = tester.widget<ListView>(listViewFinder);
        expect(listView.primary, isTrue);
        expect(listView.controller, isNull);

        // Scaffold PrimaryScrollController is linked to list
        final primaryController = PrimaryScrollController.of(
          tester.element(listViewFinder),
        );
        expect(primaryController.hasClients, isTrue);
        expect(primaryController.positions.length, equals(1));
        expect(primaryController.offset, equals(0.0));

        // Allows programmatic scrolling and extended capture without failure
        primaryController.jumpTo(100.0);
        await tester.pump();
        expect(primaryController.offset, equals(100.0));
      },
    );

    testWidgets(
      'supports passing custom ScrollController deactivating explicit primary',
      (tester) async {
        final customController = ScrollController();
        addTearDown(customController.dispose);

        await tester.pumpWidget(
          buildSubject(scrollController: customController),
        );
        await tester.pumpAndSettle();

        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        final listView = tester.widget<ListView>(listViewFinder);
        expect(listView.primary, isFalse);
        expect(listView.controller, equals(customController));
        expect(customController.hasClients, isTrue);
        expect(customController.offset, equals(0.0));

        customController.jumpTo(80.0);
        await tester.pump();
        expect(customController.offset, equals(80.0));
      },
    );

    testWidgets(
      'Scrollable associates directly with PrimaryScrollController when primary is true',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final scrollableFinder = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        );
        expect(scrollableFinder, findsOneWidget);

        final scrollable = tester.widget<Scrollable>(scrollableFinder);
        final primaryController = PrimaryScrollController.of(
          tester.element(find.byType(ListView)),
        );
        expect(scrollable.controller, equals(primaryController));
      },
    );
  });

  group(
    'OcrReviewScreen - Register products and synonyms (T-B11, RF-044, RF-045)',
    () {
      testWidgets(
        'displays options Register product and Link existing for unknown item and allows registering new product',
        (tester) async {
          ReceiptDraft? savedDraft;

          final draftWithUnknownItem = ReceiptDraft(
            store: const StoreDraft(name: 'Mercado Exemplo'),
            purchasedAt: DateTime(2026, 10, 16, 10, 0),
            items: [
              ReceiptItemDraft(
                rawDescription: 'BEB VEG AMENDOA 1L',
                quantity: const Quantity(1000, Unit.l),
                unitPrice: const Money(1590),
                totalPrice: const Money(1590),
                confidence: 0.95,
                selected: true,
                match: null, // Item sem match
              ),
            ],
            total: const Money(1590),
            confidence: 0.95,
          );

          await tester.pumpWidget(
            buildSubject(
              draft: draftWithUnknownItem,
              onSave: (draft) => savedDraft = draft,
            ),
          );
          await tester.pumpAndSettle();

          // Verify quick action buttons for unlinked item
          expect(find.byKey(const Key('btn_create_product_0')), findsOneWidget);
          expect(find.byKey(const Key('btn_link_existing_0')), findsOneWidget);

          // Toca em Cadastrar produto
          await tester.tap(find.byKey(const Key('btn_create_product_0')));
          await tester.pumpAndSettle();

          expect(find.text('Cadastrar novo produto'), findsOneWidget);

          // Fill dialog fields
          final nameField = find.widgetWithText(
            TextFormField,
            'Nome canônico *',
          );
          await tester.enterText(nameField, 'Bebida Vegetal de Amêndoa 1L');

          final catField = find.widgetWithText(TextFormField, 'Categoria *');
          await tester.enterText(catField, 'Bebidas Vegetais');

          // Tap Save in registration dialog
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(ElevatedButton, 'Salvar'),
            ),
          );
          await tester.pumpAndSettle();

          // Verifica que agora o produto cadastrado aparece vinculado na lista
          expect(find.text('Bebida Vegetal de Amêndoa 1L'), findsOneWidget);
          expect(
            find.text('detectado como BEB VEG AMENDOA 1L'),
            findsOneWidget,
          );

          // Unknown item buttons must no longer appear for this item
          expect(find.byKey(const Key('btn_create_product_0')), findsNothing);

          // Save review
          await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
          await tester.pumpAndSettle();

          expect(savedDraft, isNotNull);
          final matchedItem = savedDraft!.items.first;
          expect(matchedItem.match, isNotNull);
          expect(
            matchedItem.match!.product.canonicalName,
            equals('Bebida Vegetal de Amêndoa 1L'),
          );
          expect(
            matchedItem.match!.product.categoryId,
            equals('Bebidas Vegetais'),
          );
          expect(matchedItem.match!.product.defaultUnit, equals(Unit.l));
        },
      );

      testWidgets(
        'allows linking unknown item to existing product in catalog',
        (tester) async {
          ReceiptDraft? savedDraft;

          final existingProduct = Product(
            id: 'prod_cafe_250g',
            canonicalName: 'Café Torrado e Moído 250g',
            categoryId: 'Mercearia',
            defaultUnit: Unit.g,
            createdAt: DateTime(2026, 10, 16),
            updatedAt: DateTime(2026, 10, 16),
          );

          final draftWithUnknownItem = ReceiptDraft(
            store: const StoreDraft(name: 'Mercado Exemplo'),
            purchasedAt: DateTime(2026, 10, 16, 10, 0),
            items: [
              ReceiptItemDraft(
                rawDescription: 'CF MOIDO 250G',
                quantity: const Quantity(1000, Unit.un),
                unitPrice: const Money(1200),
                totalPrice: const Money(1200),
                confidence: 0.90,
                selected: true,
                match: null,
              ),
            ],
            total: const Money(1200),
            confidence: 0.90,
          );

          await tester.pumpWidget(
            buildSubject(
              draft: draftWithUnknownItem,
              availableProducts: [existingProduct],
              onSave: (draft) => savedDraft = draft,
            ),
          );
          await tester.pumpAndSettle();

          // Toca em Vincular existente
          await tester.tap(find.byKey(const Key('btn_link_existing_0')));
          await tester.pumpAndSettle();

          expect(find.text('Vincular produto'), findsOneWidget);
          expect(find.text('Café Torrado e Moído 250g'), findsOneWidget);

          // Seleciona o produto sugerido
          await tester.tap(find.text('Café Torrado e Moído 250g'));
          await tester.pumpAndSettle();

          // Item now linked to coffee
          expect(find.text('Café Torrado e Moído 250g'), findsOneWidget);

          // Salva
          await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
          await tester.pumpAndSettle();

          expect(savedDraft, isNotNull);
          expect(
            savedDraft!.items.first.match?.product.id,
            equals('prod_cafe_250g'),
          );
          expect(
            savedDraft!.items.first.rawDescription,
            equals('CF MOIDO 250G'),
          );
        },
      );

      testWidgets('allows registering new product inside item edit modal', (
        tester,
      ) async {
        ReceiptDraft? savedDraft;

        final draftWithUnknownItem = ReceiptDraft(
          store: const StoreDraft(name: 'Mercado Exemplo'),
          purchasedAt: DateTime(2026, 10, 16, 10, 0),
          items: [
            ReceiptItemDraft(
              rawDescription: 'IOGURTE GREGO 100G',
              quantity: const Quantity(1000, Unit.un),
              unitPrice: const Money(450),
              totalPrice: const Money(450),
              confidence: 0.85,
              selected: true,
              match: null,
            ),
          ],
          total: const Money(450),
          confidence: 0.85,
        );

        await tester.pumpWidget(
          buildSubject(
            draft: draftWithUnknownItem,
            onSave: (draft) => savedDraft = draft,
          ),
        );
        await tester.pumpAndSettle();

        // Open item edit modal
        await tester.tap(find.byTooltip('Editar item'));
        await tester.pumpAndSettle();

        // In unlinked item edit modal, Register product button is present
        final dialogCreateBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(OutlinedButton, 'Cadastrar produto'),
        );
        expect(dialogCreateBtn, findsOneWidget);
        await tester.tap(dialogCreateBtn);
        await tester.pumpAndSettle();

        expect(find.text('Cadastrar novo produto'), findsOneWidget);

        final nameField = find.widgetWithText(TextFormField, 'Nome canônico *');
        await tester.enterText(nameField, 'Iogurte Grego Tradicional 100g');

        await tester.tap(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.widgetWithText(ElevatedButton, 'Salvar'),
              )
              .last,
        );
        await tester.pumpAndSettle();

        // Save item edit modal
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Salvar'),
          ),
        );
        await tester.pumpAndSettle();

        // Save review screen
        await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
        await tester.pumpAndSettle();

        expect(savedDraft, isNotNull);
        expect(
          savedDraft!.items.first.match?.product.canonicalName,
          equals('Iogurte Grego Tradicional 100g'),
        );
      });
    },
  );
}
