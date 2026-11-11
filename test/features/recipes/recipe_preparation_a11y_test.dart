import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/recipes/data/adapters/keep_screen_on_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/ports/keep_screen_on_port.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_preparation_screen.dart';

class FakeKeepScreenOn implements KeepScreenOnPort {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

void main() {
  testWidgets('Acessibilidade do modo de preparo em textScale 2.0 (A11Y-4)', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    // Set a typical phone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeKeepScreenOn = FakeKeepScreenOn();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [keepScreenOnProvider.overrideWithValue(fakeKeepScreenOn)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            );
          },
          home: const RecipePreparationScreen(recipeId: '123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final exception = tester.takeException();
    expect(exception, isNull);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    handle.dispose();
  });
}
