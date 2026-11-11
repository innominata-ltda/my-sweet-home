import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' as db_pkg;
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/features/expenses/data/recurrence/expense_materializer.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_screen.dart';

import '../../fakes/fake_clock.dart';

void main() {
  late db_pkg.AppDatabase db;
  late FakeClock clock;
  late DriftExpenseRepository repo;
  late ExpenseMaterializer materializer;

  final categories = [
    const Category(
      id: CategoryId('cat-food'),
      name: 'Alimentação',
      kind: CategoryKind.expense,
      iconKey: 'cart',
      isSystem: true,
    ),
  ];

  setUp(() async {
    db = db_pkg.AppDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    repo = DriftExpenseRepository(
      db: db,
      clock: clock,
      idGenerator: const UuidV7Generator(),
      trashPolicy: DriftTrashPolicy(db: db, clock: clock),
    );
    materializer = ExpenseMaterializer(
      db: db,
      idGenerator: const UuidV7Generator(),
    );
    await db
        .into(db.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'cat-food',
            name: 'Alimentação',
            kind: 'expense',
            iconKey: 'cart',
            colorHex: const Value(null),
            isSystem: const Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildScreen({DateTime? initialDate, bool initialRecurring = false}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: QuickAddExpenseScreen(
        repository: repo,
        clock: clock,
        categories: categories,
        initialDate: initialDate,
        initialRecurring: initialRecurring,
      ),
    );
  }

  testWidgets(
    'CA-2.4: Salva despesa a cada 4 dias com data inicial 01/03/2026 e clock 10/03/2026, materializa em 01/03, 05/03 e 09/03',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          initialDate: DateTime.utc(2026, 3, 1),
          initialRecurring: true,
        ),
      );
      await tester.pumpAndSettle();

      // Digita o valor
      await tester.enterText(find.byType(AppMoneyField), '50,00');
      await tester.pumpAndSettle();

      // Seleciona categoria
      await tester.tap(find.text('Alimentação'));
      await tester.pumpAndSettle();

      // Selects "Every X days" option in recurrence selector
      await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A cada X dias').last);
      await tester.pumpAndSettle();

      // Informa 4 no campo de quantidade de dias
      expect(find.byKey(const Key('custom_days_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('custom_days_field')), '4');
      await tester.pumpAndSettle();

      // Salva
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Screen must have been closed successfully
      expect(find.byType(QuickAddExpenseScreen), findsNothing);

      // Regra persistida em recurring_rules
      final rules = await db.select(db.recurringRules).get();
      expect(rules.length, 1);
      final rule = rules.first;
      expect(rule.kind, 'expense');
      expect(rule.rrule, 'FREQ=DAILY;INTERVAL=4');
      expect(rule.startsOn, '2026-03-01');

      // Materialization generates occurrences on 01/03, 05/03 and 09/03
      final countResult = await materializer.materializeUpTo(clock.nowUtc());
      expect(countResult.valueOrNull, 3);

      final expenses = await db.select(db.expenses).get();
      expect(expenses.length, 3);
      final dates = expenses.map((e) => e.occurredOn).toList()..sort();
      expect(dates, ['2026-03-01', '2026-03-05', '2026-03-09']);

      // Repeated materialization is idempotent (0 new occurrences)
      final secondMaterialization = await materializer.materializeUpTo(
        clock.nowUtc(),
      );
      expect(secondMaterialization.valueOrNull, 0);
      final expensesAfterSecond = await db.select(db.expenses).get();
      expect(expensesAfterSecond.length, 3);
    },
  );

  testWidgets(
    'CA-2.5: Rejeita campo vazio na opção "A cada X dias" e exibe validação',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          initialDate: DateTime.utc(2026, 3, 1),
          initialRecurring: true,
        ),
      );
      await tester.pumpAndSettle();

      // Digita valor
      await tester.enterText(find.byType(AppMoneyField), '50,00');
      await tester.pumpAndSettle();

      // Seleciona categoria
      await tester.tap(find.text('Alimentação'));
      await tester.pumpAndSettle();

      // Seleciona "A cada X dias"
      await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A cada X dias').last);
      await tester.pumpAndSettle();

      // Deixa campo de dias vazio
      await tester.enterText(find.byKey(const Key('custom_days_field')), '');
      await tester.pumpAndSettle();

      // Tenta salvar
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Form prevents saving (remains displayed)
      expect(find.byType(QuickAddExpenseScreen), findsOneWidget);

      // Displays validation message on field
      expect(
        find.textContaining('Informe a quantidade de dias'),
        findsOneWidget,
      );

      // Nada foi persistido em recurring_rules
      final rules = await db.select(db.recurringRules).get();
      expect(rules, isEmpty);
    },
  );

  testWidgets(
    'CA-2.5: Rejeita valor 0 na opção "A cada X dias" e exibe validação',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          initialDate: DateTime.utc(2026, 3, 1),
          initialRecurring: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppMoneyField), '50,00');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alimentação'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A cada X dias').last);
      await tester.pumpAndSettle();

      // Informa 0
      await tester.enterText(find.byKey(const Key('custom_days_field')), '0');
      await tester.pumpAndSettle();

      // Tenta salvar
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Prevents saving and displays validation
      expect(find.byType(QuickAddExpenseScreen), findsOneWidget);
      expect(
        find.textContaining('Informe um número de dias válido'),
        findsOneWidget,
      );

      final rules = await db.select(db.recurringRules).get();
      expect(rules, isEmpty);
    },
  );

  testWidgets(
    'CA-2.5: Rejeita valor inválido (> 365) na opção "A cada X dias"',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          initialDate: DateTime.utc(2026, 3, 1),
          initialRecurring: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppMoneyField), '50,00');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alimentação'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A cada X dias').last);
      await tester.pumpAndSettle();

      // Informa 400 (> 365)
      await tester.enterText(find.byKey(const Key('custom_days_field')), '400');
      await tester.pumpAndSettle();

      // Tenta salvar
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Prevents saving and displays validation
      expect(find.byType(QuickAddExpenseScreen), findsOneWidget);
      expect(
        find.textContaining('Informe um número de dias válido'),
        findsOneWidget,
      );

      final rules = await db.select(db.recurringRules).get();
      expect(rules, isEmpty);
    },
  );

  testWidgets('CA-2.5: Rejects negative value in "Every X days" option', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(
        initialDate: DateTime.utc(2026, 3, 1),
        initialRecurring: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(AppMoneyField), '50,00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alimentação'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A cada X dias').last);
    await tester.pumpAndSettle();

    // Informa valor negativo
    await tester.enterText(find.byKey(const Key('custom_days_field')), '-5');
    await tester.pumpAndSettle();

    // Tenta salvar
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Prevents saving and displays validation
    expect(find.byType(QuickAddExpenseScreen), findsOneWidget);
    expect(
      find.textContaining('Informe um número de dias válido'),
      findsOneWidget,
    );

    final rules = await db.select(db.recurringRules).get();
    expect(rules, isEmpty);
  });

  testWidgets(
    'Edição de despesa permite configurar recorrência personalizada "A cada X dias"',
    (tester) async {
      // Cria uma despesa inicial avulsa
      final created = await repo.add(
        NewExpense(
          amount: const Money(1500),
          occurredOn: DateTime.utc(2026, 3, 1),
          description: 'Café',
          categoryId: const CategoryId('cat-food'),
        ),
      );
      final initialExpense = created.valueOrNull!;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuickAddExpenseScreen(
            repository: repo,
            clock: clock,
            categories: categories,
            initialExpense: initialExpense,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enables repetition
      await tester.tap(find.byKey(const Key('repeat_switch')));
      await tester.pumpAndSettle();

      // Seleciona "A cada X dias"
      await tester.tap(find.byKey(const Key('recurrence_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A cada X dias').last);
      await tester.pumpAndSettle();

      // Digita 7 dias
      await tester.enterText(find.byKey(const Key('custom_days_field')), '7');
      await tester.pumpAndSettle();

      // Salva
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddExpenseScreen), findsNothing);

      // Regra deve ter sido salva
      final rules = await db.select(db.recurringRules).get();
      expect(rules.length, 1);
      expect(rules.first.rrule, 'FREQ=DAILY;INTERVAL=7');
      expect(rules.first.kind, 'expense');
    },
  );
}
