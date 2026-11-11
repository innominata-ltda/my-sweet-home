import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/presentation/purchases_history_screen.dart';

class _FakeRepo implements PurchaseRepository {
  List<Purchase> purchases = [];

  @override
  Future<Result<void, Failure>> save(Purchase purchase) async {
    purchases.add(purchase);
    return const Ok(null);
  }

  @override
  Future<Result<Purchase?, Failure>> findById(String id) async {
    return Ok(purchases.where((p) => p.id == id).firstOrNull);
  }

  @override
  Future<Result<List<Purchase>, Failure>> getAll() async {
    return Ok(List.of(purchases));
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    purchases.removeWhere((p) => p.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> restore(String id) async {
    return const Ok(null);
  }
}

void main() {
  testWidgets('Renders PurchasesHistoryScreen empty state', (tester) async {
    final fakeRepo = _FakeRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PurchasesHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PurchasesHistoryScreen), findsOneWidget);
    expect(find.text('Compras e Notas Fiscais'), findsOneWidget);
    expect(find.text('Nenhuma compra registrada'), findsOneWidget);
  });

  testWidgets('Renders PurchasesHistoryScreen with purchases', (tester) async {
    final fakeRepo = _FakeRepo();
    fakeRepo.purchases.add(
      Purchase(
        id: 'p1',
        storeId: 'Supermercado Central',
        date: DateTime.utc(2026, 4, 1),
        items: const [],
        totalAmount: const Money(15000),
        discountAmount: Money.zero,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PurchasesHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Supermercado Central'), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsOneWidget);
  });

  testWidgets(
    'Displays original item rawDescription and canonical name in purchase details sheet',
    (tester) async {
      final fakeRepo = _FakeRepo();
      fakeRepo.purchases.add(
        Purchase(
          id: 'p1',
          storeId: 'Supermercado Central',
          date: DateTime.utc(2026, 4, 1),
          items: const [
            PurchaseItem(
              id: 'item1',
              productId: 'p_prod',
              rawDescription: 'LEITE INT TIROL 1L',
              quantity: Quantity(1000, Unit.l),
              unitPrice: Money(450),
              totalPrice: Money(450),
            ),
          ],
          totalAmount: const Money(450),
          discountAmount: Money.zero,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchaseRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PurchasesHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the purchase card to open details sheet
      await tester.tap(find.text('Supermercado Central'));
      await tester.pumpAndSettle();

      // Verify rawDescription is displayed
      expect(find.text('LEITE INT TIROL 1L'), findsOneWidget);
      expect(find.text('R\$ 4,50'), findsWidgets);
    },
  );

  testWidgets('Verifies scan receipt button exists in AppBar with tooltip', (
    tester,
  ) async {
    final fakeRepo = _FakeRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PurchasesHistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scanButton = find.byTooltip('Escanear Nota Fiscal');
    expect(scanButton, findsOneWidget);
  });
}
