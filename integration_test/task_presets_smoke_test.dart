import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/app/app.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/seed_loader.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/preset_tile.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

import '../test/fakes/fake_clock.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Modo avião ativo (RN-088): nenhuma requisição de rede permitida.',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets(
    'T-V1 (CA-7.1): Adicionar predefinição Lavar roupa, reiniciar app, verificar no calendário e concluir gerando próxima ocorrência',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.memory();
      final clock = FakeClock(DateTime.utc(2026, 3, 10, 10));
      final seedLoader = SeedLoader(db, const UuidV7Generator(), clock);
      await seedLoader.loadIfNeeded();

      // 1. Inicia o app limpo
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(clock),
          ],
          child: const MySweetHomeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Navigate to Tasks tab
      final tasksTab = find.byIcon(AppIcons.tasks).last;
      expect(tasksTab, findsOneWidget);
      await tester.tap(tasksTab);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarPage), findsOneWidget);

      // 3. Verify empty state card with button to open catalog
      final emptyStateButton = find.text('Ver sugestões para a casa');
      expect(emptyStateButton, findsOneWidget);

      // 4. Click empty state button to open catalog
      await tester.tap(emptyStateButton);
      await tester.pumpAndSettle();
      expect(find.byType(TaskPresetCatalogPage), findsOneWidget);

      // 5. Search and select task preset
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Lavar roupa');
      await tester.pumpAndSettle();

      final washClothesTile = find.widgetWithText(
        TaskPresetTile,
        'Lavar roupa',
      );
      expect(washClothesTile, findsOneWidget);
      await tester.tap(washClothesTile);
      await tester.pumpAndSettle();

      // 6. Confirm in QuickAddTaskSheet by tapping Save
      final saveButton = find.text('Salvar');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 7. Simulate app restart
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(clock),
          ],
          child: const MySweetHomeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate back to tasks tab
      await tester.tap(find.byIcon(AppIcons.tasks).last);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarPage), findsOneWidget);

      // 8. Verify preset task appears in calendar
      expect(find.text('Lavar roupa'), findsOneWidget);

      // 9. Complete task by checking checkbox
      final checkbox = find.byType(CuteCheckbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // 10. Verify in database that task was completed and next occurrence generated
      final allTasks = await db.select(db.tasks).get();
      expect(allTasks.length, 2);

      final completedTask = allTasks.firstWhere((t) => t.isCompleted);
      expect(completedTask.title, 'Lavar roupa');
      expect(completedTask.sourcePresetId, 'wash-clothes');
      expect(completedTask.completedAt, isNotNull);

      final nextOccurrence = allTasks.firstWhere((t) => !t.isCompleted);
      expect(nextOccurrence.title, 'Lavar roupa');
      expect(nextOccurrence.sourcePresetId, 'wash-clothes');
      expect(nextOccurrence.recurringRuleId, completedTask.recurringRuleId);
      // Next weekly occurrence (7 days after 2026-03-10): 2026-03-17
      expect(nextOccurrence.dueAt, startsWith('2026-03-17'));

      // Desmonta e limpa
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    },
  );
}
