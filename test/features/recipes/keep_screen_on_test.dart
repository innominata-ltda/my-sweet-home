import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/recipes/data/adapters/keep_screen_on_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/ports/keep_screen_on_port.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_preparation_screen.dart';

class FakeKeepScreenOn implements KeepScreenOnPort {
  bool enabled = false;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enabled = true;
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    enabled = false;
    disableCalls++;
  }
}

void main() {
  testWidgets(
    'Tela de preparo mantém a tela acesa e libera no dispose (CA-6.1)',
    (tester) async {
      final fakeKeepScreenOn = FakeKeepScreenOn();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [keepScreenOnProvider.overrideWithValue(fakeKeepScreenOn)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RecipePreparationScreen(recipeId: '123'),
          ),
        ),
      );

      // Initial state: enable() should be called.
      expect(fakeKeepScreenOn.enableCalls, 1);
      expect(fakeKeepScreenOn.enabled, true);

      // Dispose the widget by pumping another widget
      await tester.pumpWidget(const SizedBox());

      // Final state: disable() should be called.
      expect(fakeKeepScreenOn.disableCalls, 1);
      expect(fakeKeepScreenOn.enabled, false);
    },
  );
}
