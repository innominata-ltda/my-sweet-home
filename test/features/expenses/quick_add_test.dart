import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

void main() {
  testWidgets('Counts taps in expense entry flow (CA-1.2)', (tester) async {
    final clock = SystemClock();
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

    // O campo de valor recebe foco automaticamente (autofocus = true)
    // Thus, upon opening screen we are ready to type.
    // 1 toque (digitar valor)
    await tester.enterText(find.byType(AppMoneyField), '12,50');
    await tester.pumpAndSettle();

    // 2 toque (escolher categoria)
    await tester.tap(find.text('Mercado'));
    await tester.pumpAndSettle();

    // 3 toque (salvar)
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verifica se salvou (fechou a tela)
    expect(find.byType(QuickAddExpenseScreen), findsNothing);

    // And expense must be in repository
    final month = YearMonth.of(clock.nowUtc().toLocal());
    final result = await repo.ofMonth(month);
    result.fold((list) {
      expect(list.length, 1);
      expect(list.first.amount.cents, 1250);
      expect(list.first.categoryId?.value, 'cat1');
    }, (err) => fail('Erro ao buscar despesas'));
  });
}
