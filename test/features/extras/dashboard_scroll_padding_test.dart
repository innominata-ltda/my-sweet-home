import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../../fakes/fake_bill_payment_repository.dart';
import '../../fakes/fake_bill_repository.dart';
import '../../fakes/sequential_id_generator.dart';

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  MonthSummary summary;
  _FakeMonthSummaryRepo(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async =>
      Ok(summary);
}

class _FakeTaskRepo implements TaskRepository {
  List<task_models.Task> tasks;
  _FakeTaskRepo(this.tasks);

  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async => Ok(tasks);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShoppingListRepo implements ShoppingListRepository {
  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'T-B06: Dashboard ListView possui padding inferior para evitar sobreposição do FAB',
    (tester) async {
      final fakeMonthRepo = _FakeMonthSummaryRepo(
        MonthSummary(
          month: YearMonth('2026-10'),
          actual: const Money(0),
          budget: const Money(100000),
          remaining: const Money(100000),
          byCategory: const [],
          monthsOfHistory: 1,
        ),
      );
      final fakeTaskRepo = _FakeTaskRepo([]);
      final fakeBillRepo = FakeBillRepository(SequentialIdGenerator());
      final fakePaymentRepo = FakeBillPaymentRepository();
      final fakeShoppingRepo = _FakeShoppingListRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mascotConfigStreamProvider.overrideWith(
              (ref) => Stream.value(MascotConfig.defaultMomo),
            ),
            monthSummaryRepositoryProvider.overrideWithValue(fakeMonthRepo),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
            billRepositoryProvider.overrideWithValue(fakeBillRepo),
            billPaymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
            shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
          ],
          child: MaterialApp(
            theme: lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      final padding = listView.padding as EdgeInsets;

      expect(padding.bottom, greaterThanOrEqualTo(Spacing.xxl + 48));
    },
  );
}
