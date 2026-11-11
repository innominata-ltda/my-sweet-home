import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/week_view.dart';

void main() {
  Widget buildSubject({
    required DateTime focusedDate,
    List<Task> tasks = const [],
    void Function(Task)? onEditTask,
    void Function(Task)? onDeleteTask,
    Locale locale = const Locale('pt', 'BR'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      home: Scaffold(
        body: WeekView(
          focusedDate: focusedDate,
          tasks: tasks,
          onEditTask: onEditTask,
          onDeleteTask: onDeleteTask,
        ),
      ),
    );
  }

  testWidgets(
    'Cabeçalho da visão semanal exibe dia da semana e dia do mês (T-B13 / RF-080, CA-1.1)',
    (tester) async {
      // 2026-10-16 is a Friday
      final focusedDate = DateTime.utc(2026, 10, 16);
      // Week Monday is 2026-10-12
      final monday = DateTime.utc(2026, 10, 12);

      await tester.pumpWidget(buildSubject(focusedDate: focusedDate));
      await tester.pumpAndSettle();

      final format = DateFormat.E('pt_BR');

      // Verify each of the 7 days displays both the weekday name and the day number
      for (var i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final weekdayName = format.format(day);
        final dayNumber = '${day.day}';

        expect(find.text(weekdayName), findsOneWidget);
        expect(find.text(dayNumber), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Visão semanal exibe tarefas distribuídas nos dias correspondentes',
    (tester) async {
      final focusedDate = DateTime.utc(2026, 10, 16);

      final taskMonday = Task(
        id: 't-mon',
        title: 'Comprar pão',
        allDay: true,
        dueAt: DateTime.utc(2026, 10, 12),
        isCompleted: false,
        syncState: SyncState.synced,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      );

      final taskFriday = Task(
        id: 't-fri',
        title: 'Faxina geral',
        allDay: true,
        dueAt: DateTime.utc(2026, 10, 16),
        isCompleted: true,
        syncState: SyncState.synced,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      );

      await tester.pumpWidget(
        buildSubject(focusedDate: focusedDate, tasks: [taskMonday, taskFriday]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comprar pão'), findsOneWidget);
      expect(find.text('Faxina geral'), findsOneWidget);
    },
  );
}
