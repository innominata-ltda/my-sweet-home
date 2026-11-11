import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task;
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange range) async {
    return const Ok([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  Widget createWidget() {
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
    'T-B16: Botões de navegação de mês e FAB no Calendário possuem tooltip e acessibilidade pt-BR',
    (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 1. Previous month
      expect(find.byTooltip('Mês anterior'), findsOneWidget);
      expect(find.bySemanticsLabel('Mês anterior'), findsOneWidget);

      // 2. Next month
      expect(find.byTooltip('Próximo mês'), findsOneWidget);
      expect(find.bySemanticsLabel('Próximo mês'), findsOneWidget);

      // 3. FAB Nova tarefa
      expect(find.byTooltip('Nova tarefa'), findsOneWidget);
      expect(find.bySemanticsLabel('Nova tarefa'), findsOneWidget);

      // Desmonta e drena timers pendentes do Drift QueryStream
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
