import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_task_from_preset.dart';
import '../fakes/fake_task_preset_catalog.dart';

Widget _buildTestApp({
  required Widget child,
  required ThemeData theme,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: child,
      ),
    ),
  );
}

void main() {
  late FakeClock clock;
  late FakeTaskPresetCatalog fakeCatalog;
  late FakeTaskFromPreset fakeTaskFromPreset;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    fakeCatalog = FakeTaskPresetCatalog.defaultFixture();
    fakeTaskFromPreset = FakeTaskFromPreset(activeIds: {'wash-clothes'});
  });

  testWidgets('TaskPresetCatalogPage golden — tema claro', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        theme: lightTheme(),
        child: TaskPresetCatalogPage(
          catalogPort: fakeCatalog,
          taskFromPresetPort: fakeTaskFromPreset,
          clock: clock,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TaskPresetCatalogPage),
      matchesGoldenFile('task_presets_catalog_light.png'),
    );
  });

  testWidgets('TaskPresetCatalogPage golden — tema escuro', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        theme: darkTheme(),
        child: TaskPresetCatalogPage(
          catalogPort: fakeCatalog,
          taskFromPresetPort: fakeTaskFromPreset,
          clock: clock,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TaskPresetCatalogPage),
      matchesGoldenFile('task_presets_catalog_dark.png'),
    );
  });

  testWidgets('TaskPresetCatalogPage golden — textScale 2.0', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildTestApp(
        theme: lightTheme(),
        textScaleFactor: 2.0,
        child: TaskPresetCatalogPage(
          catalogPort: fakeCatalog,
          taskFromPresetPort: fakeTaskFromPreset,
          clock: clock,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TaskPresetCatalogPage),
      matchesGoldenFile('task_presets_catalog_text_scale_2.png'),
    );
  });
}
