import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quick add expense duration is under 15s in real user flow', (
    tester,
  ) async {
    const clock = SystemClock();
    final repo = FakeExpenseRepository(clock);
    final categories = [
      const Category(
        id: CategoryId('cat1'),
        name: 'Mercado',
        kind: CategoryKind.expense,
        iconKey: 'shopping_cart',
        isSystem: true,
      ),
      const Category(
        id: CategoryId('cat2'),
        name: 'Lazer',
        kind: CategoryKind.expense,
        iconKey: 'movie',
        isSystem: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QuickAddExpenseScreen(
          repository: repo,
          clock: clock,
          categories: categories,
        ),
      ),
    );

    // The field gains autofocus, so measure duration from here
    final stopwatch = Stopwatch()..start();

    // 1. Enter amount
    await tester.enterText(find.byType(AppMoneyField), '12,50');
    await tester.pumpAndSettle();

    // 2. Select category
    await tester.tap(find.text('Mercado'));
    await tester.pumpAndSettle();

    // 3. Save
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    stopwatch.stop();

    // Verify screen closed after saving
    expect(find.byType(QuickAddExpenseScreen), findsNothing);

    // Must finish within 15 seconds
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(15000),
      reason: 'Quick add expense time must be under 15s',
    );
  });
}
