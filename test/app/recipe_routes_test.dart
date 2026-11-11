import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_screen.dart';

void main() {
  group('015/T-I01 — Recipe Routes Test', () {
    Widget buildTestApp(String initialLocation) {
      final db = AppDatabase.memory();
      return ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            router.go(initialLocation);
            return MaterialApp.router(
              theme: lightTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            );
          },
        ),
      );
    }

    testWidgets('Navega para /receitas/nova exibe RecipeDraftScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp('/receitas/nova'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeDraftScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
