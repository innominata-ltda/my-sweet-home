import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task;
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    final task = Task(
      id: 'fake_id_${tasks.length + 1}',
      title: t.title,
      allDay: t.allDay,
      dueAt: t.dueAt,
      isCompleted: false,
      syncState: SyncState.synced,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    tasks.add(task);
    return Ok(task);
  }

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(isCompleted: true);
      tasks[idx] = updated;
      return Ok(updated);
    }
    throw UnimplementedError();
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(isCompleted: false);
      tasks[idx] = updated;
      return Ok(updated);
    }
    throw UnimplementedError();
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    tasks.removeWhere((t) => t.id == id);
    return Ok(TrashTicket(table: 'tasks', id: id, deletedAt: DateTime.now()));
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async {
    return Ok(tasks);
  }

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async {
    return Ok([]);
  }

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async {
    return Ok([]);
  }

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async {
    return Ok(tasks);
  }

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async {
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
    return Ok(task);
  }

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async {
    tasks.removeWhere((t) => t.id == id);
    return const Ok(null);
  }
}

class FakeClock implements Clock {
  final DateTime _now;
  FakeClock(this._now);

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime todayUtc() => DateTime.utc(_now.year, _now.month, _now.day);
}

void main() {
  late AppDatabase db;
  late FakeTaskRepository repo;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase.memory();
    repo = FakeTaskRepository();
    clock = FakeClock(DateTime.utc(2026, 10, 15));
  });

  tearDown(() async {
    await db.close();
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        taskRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(clock),
      ],
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
        home: CalendarPage(),
      ),
    );
  }

  testWidgets(
    'Atualizar reativamente as contas exibidas no calendário quando cadastradas, alteradas ou pagas (T-B14 / RF-080, RF-082)',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Initially no bills due
      expect(find.textContaining('Contas a vencer hoje'), findsNothing);
      expect(find.textContaining('Internet Fibra'), findsNothing);

      // 1. Register a recurring bill scheduled for today
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill-1',
              title: 'Internet Fibra',
              amountCents: const drift.Value(12000),
              isAmountVariable: false,
              dueDay: 15,
              isActive: const drift.Value(true),
            ),
          );
      await db
          .into(db.billPayments)
          .insert(
            BillPaymentsCompanion.insert(
              id: 'pay-1',
              dueOn: '2026-10-15T00:00:00.000Z',
              billId: const drift.Value('bill-1'),
              amountCents: const drift.Value(12000),
              status: 'pending',
            ),
          );

      // Calendar reacts reactively to db insertions
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Contas a vencer hoje (1):'), findsOneWidget);
      expect(find.textContaining('Internet Fibra'), findsOneWidget);
      expect(find.textContaining('R\$ 120.00'), findsOneWidget);
      expect(find.textContaining('(Pendente)'), findsOneWidget);

      // 2. Edit fixed bill (title and amount changed)
      await (db.update(db.bills)..where((t) => t.id.equals('bill-1'))).write(
        const BillsCompanion(
          title: drift.Value('Internet Ultra Fibra'),
          amountCents: drift.Value(15000),
        ),
      );

      // Calendar reacts reactively to bill update
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Internet Ultra Fibra'), findsOneWidget);
      expect(find.textContaining('R\$ 150.00'), findsOneWidget);
      expect(find.textContaining('(Pendente)'), findsOneWidget);

      // 3. Pagar a conta (status e paidOn atualizados no pagamento)
      await (db.update(
        db.billPayments,
      )..where((t) => t.id.equals('pay-1'))).write(
        const BillPaymentsCompanion(
          status: drift.Value('paid'),
          paidOn: drift.Value('2026-10-15T14:30:00.000Z'),
        ),
      );

      // Calendar reacts reactively to bill payment
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Internet Ultra Fibra'), findsOneWidget);
      expect(find.textContaining('(Paga)'), findsOneWidget);
      expect(find.textContaining('(Pendente)'), findsNothing);

      // 4. Desativar/Pausar a conta (isActive = false)
      await (db.update(db.bills)..where((t) => t.id.equals('bill-1'))).write(
        const BillsCompanion(isActive: drift.Value(false)),
      );

      // Calendar reacts reactively removing inactive bills
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Contas a vencer hoje'), findsNothing);
      expect(find.textContaining('Internet Ultra Fibra'), findsNothing);

      // Desmonta o widget e drena timers pendentes do Drift QueryStream
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Visão mensal do calendário atualiza reativamente contador de contas (T-B14 / RF-082)',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Switch to Month tab
      await tester.tap(find.text('Mês'));
      await tester.pumpAndSettle();

      // Cadastra conta para o dia 20
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill-2',
              title: 'Energia Elétrica',
              amountCents: const drift.Value(25000),
              isAmountVariable: false,
              dueDay: 20,
              isActive: const drift.Value(true),
            ),
          );
      await db
          .into(db.billPayments)
          .insert(
            BillPaymentsCompanion.insert(
              id: 'pay-2',
              dueOn: '2026-10-20T00:00:00.000Z',
              billId: const drift.Value('bill-2'),
              amountCents: const drift.Value(25000),
              status: 'pending',
            ),
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Select day 20 to return to daily view
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      // Daily view of day 20 now reflects registered bill
      expect(find.textContaining('Contas a vencer hoje (1):'), findsOneWidget);
      expect(find.textContaining('Energia Elétrica'), findsOneWidget);
      expect(find.textContaining('R\$ 250.00'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Tocar em conta no calendário navega para /contas com id da conta como extra (T-B15 / RF-080, RF-082)',
    (tester) async {
      String? receivedExtra;

      final router = GoRouter(
        initialLocation: '/calendario',
        routes: [
          GoRoute(
            path: '/calendario',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/contas',
            builder: (context, state) {
              receivedExtra = state.extra as String?;
              return Scaffold(body: Text('Tela de Contas: $receivedExtra'));
            },
          ),
        ],
      );

      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill-nav-1',
              title: 'Gás de Cozinha',
              amountCents: const drift.Value(11000),
              isAmountVariable: false,
              dueDay: 15,
              isActive: const drift.Value(true),
            ),
          );
      await db
          .into(db.billPayments)
          .insert(
            BillPaymentsCompanion.insert(
              id: 'pay-nav-1',
              dueOn: '2026-10-15T00:00:00.000Z',
              billId: const drift.Value('bill-nav-1'),
              amountCents: const drift.Value(11000),
              status: 'pending',
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            taskRepositoryProvider.overrideWithValue(repo),
            clockProvider.overrideWithValue(clock),
          ],
          child: MaterialApp.router(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Gás de Cozinha'), findsOneWidget);

      final billFinder = find.byKey(const Key('calendar_bill_bill-nav-1'));
      expect(billFinder, findsOneWidget);

      await tester.tap(billFinder);
      await tester.pumpAndSettle();

      expect(find.text('Tela de Contas: bill-nav-1'), findsOneWidget);
      expect(receivedExtra, equals('bill-nav-1'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
