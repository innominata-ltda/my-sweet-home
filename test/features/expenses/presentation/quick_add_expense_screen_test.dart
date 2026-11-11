import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_screen.dart';

void main() {
  late SystemClock clock;
  late FakeExpenseRepository repo;

  final categories = [
    const Category(
      id: CategoryId('cat-1'),
      name: 'Mercado',
      kind: CategoryKind.expense,
      iconKey: 'cart',
      isSystem: true,
    ),
  ];

  setUp(() {
    clock = SystemClock();
    repo = FakeExpenseRepository(clock);
  });

  Widget buildScreen({Expense? initialExpense}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: QuickAddExpenseScreen(
        repository: repo,
        clock: clock,
        categories: categories,
        initialExpense: initialExpense,
      ),
    );
  }

  testWidgets('does not display delete button when creating new expense', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.delete), findsNothing);
    expect(find.text('Excluir despesa'), findsNothing);
  });

  testWidgets('displays delete button in edit mode', (tester) async {
    final expense = Expense(
      id: const ExpenseId('exp-1'),
      amount: const Money(4250),
      occurredOn: DateTime(2026, 10, 15),
      createdAt: DateTime(2026, 10, 15),
      description: 'Compras da semana',
    );

    await tester.pumpWidget(buildScreen(initialExpense: expense));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.delete), findsWidgets);
    expect(find.text('Excluir despesa'), findsWidgets);
  });

  testWidgets(
    'cancela exclusão ao tocar em Cancelar no diálogo de confirmação',
    (tester) async {
      final addedResult = await repo.add(
        NewExpense(
          amount: const Money(3000),
          occurredOn: clock.nowUtc().toLocal(),
          description: 'Lanche',
        ),
      );
      final expense = addedResult.valueOrNull!;

      await tester.pumpWidget(buildScreen(initialExpense: expense));
      await tester.pumpAndSettle();

      // Clicks delete button in AppBar
      final deleteIcon = find.byIcon(AppIcons.delete).first;
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Excluir despesa?'), findsOneWidget);
      expect(
        find.text('Tem certeza de que deseja excluir esta despesa?'),
        findsOneWidget,
      );

      // Clica em Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog closes and screen remains open
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(QuickAddExpenseScreen), findsOneWidget);

      // Expense still exists in repository
      final check = await repo.byId(expense.id);
      expect(check.valueOrNull, isNotNull);
    },
  );

  testWidgets('deletes expense upon confirming in dialog and closes screen', (
    tester,
  ) async {
    final addedResult = await repo.add(
      NewExpense(
        amount: const Money(5000),
        occurredOn: clock.nowUtc().toLocal(),
        description: 'Farmácia',
      ),
    );
    final expense = addedResult.valueOrNull!;

    await tester.pumpWidget(buildScreen(initialExpense: expense));
    await tester.pumpAndSettle();

    // Clicks Delete expense button (bottom button)
    final deleteButton = find.widgetWithText(OutlinedButton, 'Excluir despesa');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirmation dialog visible
    expect(find.byType(AlertDialog), findsOneWidget);

    // Confirm deletion
    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Excluir'),
    );
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Edit screen should be popped
    expect(find.byType(QuickAddExpenseScreen), findsNothing);

    // Expense removed in repository
    final check = await repo.byId(expense.id);
    expect(check.valueOrNull, isNull);

    final month = YearMonth.of(clock.nowUtc().toLocal());
    final list = await repo.ofMonth(month);
    expect(list.valueOrNull, isEmpty);
  });
}
