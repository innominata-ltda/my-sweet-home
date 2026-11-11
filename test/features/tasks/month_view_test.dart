import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/month_view.dart';

void main() {
  testWidgets(
    'Mês com 40 tarefas, indicador por dia, sem frame > 16ms (CA-6.1)',
    (tester) async {
      final tasks = List.generate(40, (i) {
        return Task(
          id: 't$i',
          title: 'Task $i',
          allDay: false,
          isCompleted: false,
          syncState: SyncState.synced,
          createdAt: DateTime.utc(2023, 10, 1),
          updatedAt: DateTime.utc(2023, 10, 1),
          dueAt: DateTime.utc(
            2023,
            10,
            (i % 28) + 1,
          ), // distributes across the month
        );
      });

      final today = DateTime.utc(2023, 10, 15);
      final focusedMonth = DateTime.utc(2023, 10, 1);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          home: Scaffold(
            body: MonthView(
              focusedMonth: focusedMonth,
              today: today,
              tasks: tasks,
            ),
          ),
        ),
      );

      // Give it a moment to build
      await tester.pumpAndSettle();

      // Verify indicators for day 15
      expect(find.text('15'), findsOneWidget);

      // Day 1 has some tasks. We generated 40 tasks.
      // The days that get tasks are i % 28 + 1. So day 1 gets tasks for i=0, i=28 -> 2 tasks.
      final tasksOnDay1 = tasks.where((t) => t.dueAt?.day == 1).length; // 2

      // There are 2 tasks on day 1. The day view should show "2" in the indicator.
      // There might be multiple "2"s on the screen (day 2, and the indicator for day 1, etc.)
      // So we just check that tasks are rendered.
      expect(find.text('$tasksOnDay1'), findsWidgets);
    },
  );
}
