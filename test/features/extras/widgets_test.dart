import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_controller.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../../fakes/fake_bill_payment_repository.dart';
import '../../fakes/fake_bill_repository.dart';
import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  final List<ShoppingList> lists;
  FakeShoppingListRepository([this.lists = const []]);

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists);
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = lists.firstWhere((l) => l.id == id);
    return Ok(list);
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    return const Ok(null);
  }
}

class FakeTaskRepository implements TaskRepository {
  final List<task_models.Task> tasks;
  FakeTaskRepository([List<task_models.Task>? tasks]) : tasks = tasks ?? [];

  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async {
    return Ok(tasks);
  }

  @override
  Future<Result<task_models.Task, Failure>> complete(
    task_models.TaskId id,
  ) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      tasks[idx] = updated;
      return Ok(updated);
    }
    return const Err(StorageFailure(detail: 'Task not found'));
  }

  @override
  Future<Result<task_models.Task, Failure>> uncomplete(
    task_models.TaskId id,
  ) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(
        isCompleted: false,
        completedAt: null,
      );
      tasks[idx] = updated;
      return Ok(updated);
    }
    return const Err(StorageFailure(detail: 'Task not found'));
  }

  @override
  Future<Result<task_models.Task, Failure>> upsert(
    task_models.NewTask t,
  ) async => throw UnimplementedError();
  @override
  Future<Result<TrashTicket, Failure>> remove(
    task_models.TaskId id, {
    required bool alsoRemote,
  }) async => throw UnimplementedError();
  @override
  Future<Result<List<task_models.Task>, Failure>> withoutDueDate() async =>
      throw UnimplementedError();
  @override
  Future<Result<List<task_models.Task>, Failure>> dirtySince(
    DateTime? mark,
  ) async => throw UnimplementedError();
  @override
  Future<Result<List<task_models.Task>, Failure>> allTasksForSync() async =>
      throw UnimplementedError();
  @override
  Future<Result<task_models.Task, Failure>> saveSyncedTask(
    task_models.Task task,
  ) async => throw UnimplementedError();
  @override
  Future<Result<void, Failure>> deleteLocalPermanently(
    task_models.TaskId id,
  ) async => throw UnimplementedError();
}

class FakeMonthSummaryRepository implements MonthSummaryRepository {
  MonthSummary? summary;
  FakeMonthSummaryRepository([this.summary]);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async {
    if (summary != null) {
      return Ok(summary!);
    }
    return Ok(
      MonthSummary(
        month: m,
        actual: const Money(0),
        byCategory: const [],
        monthsOfHistory: 0,
      ),
    );
  }
}

void main() {
  late SequentialIdGenerator idGen;
  late FakeBillRepository billRepo;
  late FakeBillPaymentRepository paymentRepo;
  late FakeClock clock;

  final now = DateTime.utc(2026, 10, 1, 10, 0);
  final monthlyRule = RecurrenceRule.tryParse('FREQ=MONTHLY')!;

  setUp(() {
    idGen = SequentialIdGenerator();
    billRepo = FakeBillRepository(idGen);
    paymentRepo = FakeBillPaymentRepository();
    clock = FakeClock(now);
  });

  group('DueBillsWidgetController', () {
    test('carrega contas a vencer offline ordenadas por data de vencimento (CA-3.1)', () async {
      final b1 = await billRepo.upsert(
        NewBill(
          title: 'Aluguel',
          categoryId: const CategoryId('cat-housing'),
          dueDay: 10,
          recurrence: monthlyRule,
          amount: const Money(120000),
          isEstimated: false,
        ),
      );

      final b2 = await billRepo.upsert(
        NewBill(
          title: 'Conta de Luz',
          categoryId: const CategoryId('cat-utilities'),
          dueDay: 5,
          recurrence: monthlyRule,
          amount: const Money(15000),
          isEstimated: false,
        ),
      );

      final bill1 = b1.valueOrNull!;
      final bill2 = b2.valueOrNull!;

      await paymentRepo.upsertOccurrences([
        BillPayment(
          id: 'pay-1',
          billId: bill1.id,
          dueOn: DateTime.utc(2026, 10, 10),
        ),
        BillPayment(
          id: 'pay-2',
          billId: bill2.id,
          dueOn: DateTime.utc(2026, 10, 5),
        ),
      ]);

      final controller = DueBillsWidgetController(
        billRepository: billRepo,
        paymentRepository: paymentRepo,
        clock: clock,
      );

      await controller.load();

      expect(controller.value, isA<DueBillsWidgetSuccess>());
      final state = controller.value as DueBillsWidgetSuccess;

      expect(state.items.length, equals(2));
      expect(state.items[0].bill.title, equals('Conta de Luz'));
      expect(state.items[1].bill.title, equals('Aluguel'));
      expect(state.items[0].dueLabel, equals('Vence em 4 dias'));
      expect(state.items[1].dueLabel, equals('Vence dia 10/10'));
    });

    test('carrega contas atrasadas do mes anterior', () async {
      final b1 = await billRepo.upsert(
        NewBill(
          title: 'Internet Setembro',
          categoryId: const CategoryId('cat-utilities'),
          dueDay: 25,
          recurrence: monthlyRule,
          amount: const Money(10000),
          isEstimated: false,
        ),
      );

      final bill1 = b1.valueOrNull!;

      await paymentRepo.upsertOccurrences([
        BillPayment(
          id: 'pay-prev-1',
          billId: bill1.id,
          dueOn: DateTime.utc(2026, 9, 25),
        ),
      ]);

      final controller = DueBillsWidgetController(
        billRepository: billRepo,
        paymentRepository: paymentRepo,
        clock: clock,
      );

      await controller.load();

      expect(controller.value, isA<DueBillsWidgetSuccess>());
      final state = controller.value as DueBillsWidgetSuccess;

      expect(state.items.length, equals(1));
      expect(state.items[0].bill.title, equals('Internet Setembro'));
      expect(state.items[0].dueLabel, equals('Atrasada'));
    });

    test('ignora contas ja pagas', () async {
      final b1 = await billRepo.upsert(
        NewBill(
          title: 'Internet',
          categoryId: const CategoryId('cat-utilities'),
          dueDay: 15,
          recurrence: monthlyRule,
          amount: const Money(10000),
          isEstimated: false,
        ),
      );

      final bill1 = b1.valueOrNull!;

      await paymentRepo.upsertOccurrences([
        BillPayment(
          id: 'pay-1',
          billId: bill1.id,
          dueOn: DateTime.utc(2026, 10, 15),
        ),
      ]);

      await paymentRepo.markPaid(
        'pay-1',
        amount: const Money(10000),
        paidOn: now,
      );

      final controller = DueBillsWidgetController(
        billRepository: billRepo,
        paymentRepository: paymentRepo,
        clock: clock,
      );

      await controller.load();

      final state = controller.value as DueBillsWidgetSuccess;
      expect(state.isEmpty, isTrue);
      expect(state.items, isEmpty);
    });

    test(
      'suporta alternar o ocultamento de valores monetarios (RN-253, CA-3.2)',
      () async {
        final controller = DueBillsWidgetController(
          billRepository: billRepo,
          paymentRepository: paymentRepo,
          clock: clock,
          hideValues: false,
        );

        await controller.load();
        var state = controller.value as DueBillsWidgetSuccess;
        expect(state.hideValues, isFalse);

        controller.setHideValues(true);
        state = controller.value as DueBillsWidgetSuccess;
        expect(state.hideValues, isTrue);
      },
    );

    test(
      'does not trigger error when disposed during asynchronous loading',
      () async {
        final controller = DueBillsWidgetController(
          billRepository: billRepo,
          paymentRepository: paymentRepo,
          clock: clock,
        );
        controller.dispose();
        await controller.load();
        // No disposed notifier exception should be thrown.
      },
    );
  });

  group('DueBillsWidget', () {
    testWidgets(
      'displays upcoming bills with titles and amounts when visible',
      (tester) async {
        final b1 = await billRepo.upsert(
          NewBill(
            title: 'Aluguel',
            categoryId: const CategoryId('cat-housing'),
            dueDay: 10,
            recurrence: monthlyRule,
            amount: const Money(120000),
            isEstimated: false,
          ),
        );
        final bill1 = b1.valueOrNull!;

        await paymentRepo.upsertOccurrences([
          BillPayment(
            id: 'pay-1',
            billId: bill1.id,
            dueOn: DateTime.utc(2026, 10, 10),
          ),
        ]);

        final controller = DueBillsWidgetController(
          billRepository: billRepo,
          paymentRepository: paymentRepo,
          clock: clock,
        );
        await controller.load();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DueBillsWidget(controller: controller)),
          ),
        );

        expect(find.text('Contas a vencer'), findsOneWidget);
        expect(find.text('Aluguel'), findsOneWidget);
        expect(find.text('R\$ 1.200,00'), findsOneWidget);
      },
    );

    testWidgets(
      'oculta valores monetarios na tela bloqueada ou com opcao ativa (RN-253, CA-3.2)',
      (tester) async {
        final b1 = await billRepo.upsert(
          NewBill(
            title: 'Aluguel',
            categoryId: const CategoryId('cat-housing'),
            dueDay: 10,
            recurrence: monthlyRule,
            amount: const Money(120000),
            isEstimated: false,
          ),
        );
        final bill1 = b1.valueOrNull!;

        await paymentRepo.upsertOccurrences([
          BillPayment(
            id: 'pay-1',
            billId: bill1.id,
            dueOn: DateTime.utc(2026, 10, 10),
          ),
        ]);

        final controller = DueBillsWidgetController(
          billRepository: billRepo,
          paymentRepository: paymentRepo,
          clock: clock,
          hideValues: true,
        );
        await controller.load();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DueBillsWidget(controller: controller)),
          ),
        );

        expect(find.text('Aluguel'), findsOneWidget);
        expect(find.text('R\$ 1.200,00'), findsNothing);
        expect(find.text('R\$ ***'), findsOneWidget);
      },
    );

    testWidgets('displays empty list state when there are no upcoming bills', (
      tester,
    ) async {
      final controller = DueBillsWidgetController(
        billRepository: billRepo,
        paymentRepository: paymentRepo,
        clock: clock,
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DueBillsWidget(controller: controller)),
        ),
      );

      expect(find.text('Contas a vencer'), findsOneWidget);
      expect(find.text('Nenhuma conta a vencer'), findsOneWidget);
    });
  });

  group('ShoppingListWidget & Controller (RF-102)', () {
    test(
      'carrega listas de compras ativas e calcula contagem de pendencias',
      () async {
        final list1 = ShoppingList(
          id: 'list-1',
          name: 'Supermercado',
          createdAt: now,
          items: [
            ShoppingItem(id: 'i1', rawText: 'Leite', parsedName: 'Leite'),
            ShoppingItem(
              id: 'i2',
              rawText: 'Pão',
              parsedName: 'Pão',
              boughtAt: now,
            ),
          ],
        );
        final list2 = ShoppingList(
          id: 'list-2',
          name: 'Arquivada',
          createdAt: now,
          isArchived: true,
          items: [],
        );

        final repo = FakeShoppingListRepository([list1, list2]);
        final controller = ShoppingListWidgetController(
          shoppingListRepository: repo,
        );

        await controller.load();

        expect(controller.value, isA<ShoppingListWidgetSuccess>());
        final state = controller.value as ShoppingListWidgetSuccess;
        expect(state.lists.length, equals(1));
        expect(state.lists.first.list.name, equals('Supermercado'));
        expect(state.lists.first.totalItems, equals(2));
        expect(state.lists.first.pendingItems, equals(1));
      },
    );

    testWidgets('exibe listas de compras e gerencia estado de lista vazia', (
      tester,
    ) async {
      final list1 = ShoppingList(
        id: 'list-1',
        name: 'Feira Semanal',
        createdAt: now,
        items: [ShoppingItem(id: 'i1', rawText: 'Maçã', parsedName: 'Maçã')],
      );

      final repo = FakeShoppingListRepository([list1]);
      final controller = ShoppingListWidgetController(
        shoppingListRepository: repo,
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShoppingListWidget(controller: controller)),
        ),
      );

      expect(find.text('Listas de compras'), findsOneWidget);
      expect(find.text('Feira Semanal'), findsOneWidget);
      expect(find.text('1 item pendente'), findsOneWidget);
    });

    testWidgets('displays empty state when there are no active lists', (
      tester,
    ) async {
      final repo = FakeShoppingListRepository([]);
      final controller = ShoppingListWidgetController(
        shoppingListRepository: repo,
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShoppingListWidget(controller: controller)),
        ),
      );

      expect(find.text('Listas de compras'), findsOneWidget);
      expect(find.text('Nenhuma lista de compras'), findsOneWidget);
    });
  });

  group('TodayTasksWidget & Controller (RF-102)', () {
    test('carrega tarefas do dia e alterna conclusao', () async {
      final t1 = task_models.Task(
        id: 't1',
        title: 'Comprar lâmpada',
        allDay: true,
        isCompleted: false,
        syncState: task_models.SyncState.synced,
        createdAt: now,
        updatedAt: now,
      );

      final repo = FakeTaskRepository([t1]);
      final controller = TodayTasksWidgetController(taskRepository: repo);

      await controller.load();

      expect(controller.value, isA<TodayTasksWidgetSuccess>());
      var state = controller.value as TodayTasksWidgetSuccess;
      expect(state.tasks.length, equals(1));
      expect(state.pendingCount, equals(1));

      await controller.toggleComplete('t1');
      state = controller.value as TodayTasksWidgetSuccess;
      expect(state.tasks.first.isCompleted, isTrue);
      expect(state.pendingCount, equals(0));
    });

    testWidgets('exibe tarefas do dia e suporta toque de conclusao', (
      tester,
    ) async {
      final t1 = task_models.Task(
        id: 't1',
        title: 'Trocar o lixo',
        allDay: true,
        isCompleted: false,
        syncState: task_models.SyncState.synced,
        createdAt: now,
        updatedAt: now,
      );

      final repo = FakeTaskRepository([t1]);
      final controller = TodayTasksWidgetController(taskRepository: repo);
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayTasksWidget(controller: controller)),
        ),
      );

      expect(find.text('Tarefas de hoje'), findsOneWidget);
      expect(find.text('Trocar o lixo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('today_task_check_t1')));
      await tester.pump();

      final state = controller.value as TodayTasksWidgetSuccess;
      expect(state.tasks.first.isCompleted, isTrue);
    });

    testWidgets('displays empty state when there are no tasks today', (
      tester,
    ) async {
      final repo = FakeTaskRepository([]);
      final controller = TodayTasksWidgetController(taskRepository: repo);
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayTasksWidget(controller: controller)),
        ),
      );

      expect(find.text('Tarefas de hoje'), findsOneWidget);
      expect(find.text('Nenhuma tarefa para hoje'), findsOneWidget);
    });
  });

  group('MonthBalanceWidget & Controller (RF-102, RN-253, CA-3.2)', () {
    test('carrega resumo do saldo do mes e alterna hideValues', () async {
      final summary = MonthSummary(
        month: YearMonth.of(now),
        actual: const Money(45000),
        budget: const Money(100000),
        remaining: const Money(55000),
        byCategory: const [],
        monthsOfHistory: 1,
      );

      final repo = FakeMonthSummaryRepository(summary);
      final controller = MonthBalanceWidgetController(
        monthSummaryRepository: repo,

        hideValues: false,
      );

      await controller.load();

      expect(controller.value, isA<MonthBalanceWidgetSuccess>());
      var state = controller.value as MonthBalanceWidgetSuccess;
      expect(state.summary.actual, equals(const Money(45000)));
      expect(state.hideValues, isFalse);

      controller.setHideValues(true);
      state = controller.value as MonthBalanceWidgetSuccess;
      expect(state.hideValues, isTrue);
    });

    testWidgets(
      'exibe saldo do mes com valores formatados e oculta com hideValues=true (RN-253, CA-3.2)',
      (tester) async {
        final summary = MonthSummary(
          month: YearMonth.of(now),
          actual: const Money(45000),
          budget: const Money(100000),
          remaining: const Money(55000),
          byCategory: const [],
          monthsOfHistory: 1,
        );

        final repo = FakeMonthSummaryRepository(summary);
        final controller = MonthBalanceWidgetController(
          monthSummaryRepository: repo,
          clock: clock,
          hideValues: false,
        );
        await controller.load();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MonthBalanceWidget(controller: controller)),
          ),
        );

        expect(find.text('Saldo do mês'), findsOneWidget);
        expect(find.text('R\$ 450,00'), findsOneWidget);
        expect(find.text('R\$ 550,00'), findsOneWidget);

        // Agora testa com ocultamento ativo
        controller.setHideValues(true);
        await tester.pump();

        expect(find.text('R\$ 450,00'), findsNothing);
        expect(
          find.textContaining('R\$ ***'),
          findsNWidgets(3),
        ); // actual, remaining, budget
      },
    );
  });
}
