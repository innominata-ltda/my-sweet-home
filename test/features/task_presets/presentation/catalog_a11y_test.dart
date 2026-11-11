import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/preset_tile.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/fake_task_from_preset.dart';
import '../../../fakes/fake_task_preset_catalog.dart';

Widget _wrap({
  required Widget child,
  double textScaleFactor = 1.0,
  ThemeData? theme,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
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

  group('T-08: Accessibility of presets catalog (RNF-006, A11Y-2, A11Y-5)', () {
    testWidgets(
      'Each preset is announced with title, frequency, area, and state',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          _wrap(
            child: TaskPresetCatalogPage(
              catalogPort: fakeCatalog,
              taskFromPresetPort: fakeTaskFromPreset,
              clock: clock,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Wash-clothes is in active routine -> should include title, frequency, area and routine badge
        final washClothesTile = find.byWidgetPredicate(
          (w) => w is TaskPresetTile && w.preset.id == 'wash-clothes',
        );
        expect(washClothesTile, findsOneWidget);

        final washClothesSemantics = tester.getSemantics(washClothesTile);
        expect(washClothesSemantics.label, contains('Lavar roupa'));
        expect(washClothesSemantics.label, contains('toda semana'));
        expect(washClothesSemantics.label, contains('\u00E1rea Roupas'));
        expect(washClothesSemantics.label, contains('Já na sua rotina'));

        // Sweep-floor is not in routine -> should not contain routine badge
        final sweepTile = find.byWidgetPredicate(
          (w) => w is TaskPresetTile && w.preset.id == 'sweep-floor',
        );
        expect(sweepTile, findsOneWidget);

        final sweepSemantics = tester.getSemantics(sweepTile);
        expect(sweepSemantics.label, contains('Varrer o chão'));
        expect(sweepSemantics.label, contains('a cada 3 dias'));
        expect(sweepSemantics.label, contains('área Limpeza geral'));
        expect(sweepSemantics.label, isNot(contains('Já na sua rotina')));

        handle.dispose();
      },
    );

    testWidgets(
      'Alvos de toque dos cards respeitam altura mínima de 48dp (RNF-006)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: TaskPresetCatalogPage(
              catalogPort: fakeCatalog,
              taskFromPresetPort: fakeTaskFromPreset,
              clock: clock,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final tiles = tester.widgetList<TaskPresetTile>(
          find.byType(TaskPresetTile),
        );
        expect(tiles, isNotEmpty);

        for (var i = 0; i < tiles.length; i++) {
          final size = tester.getSize(find.byType(TaskPresetTile).at(i));
          expect(size.height, greaterThanOrEqualTo(48.0));
        }
      },
    );

    testWidgets(
      'Escala de texto 2.0 não causa overflow no catálogo (RNF-006)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScaleFactor: 2.0,
            child: TaskPresetCatalogPage(
              catalogPort: fakeCatalog,
              taskFromPresetPort: fakeTaskFromPreset,
              clock: clock,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Sugestões para a casa'), findsOneWidget);
      },
    );
  });
}
