import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/sync/presentation/household_screen.dart';

void main() {
  group('013/T-I03 — Household Route Test', () {
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
              routerConfig: router,
            );
          },
        ),
      );
    }

    testWidgets('Navega para /ajustes/casa exibe HouseholdScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp('/ajustes/casa'));
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdScreen), findsOneWidget);
      expect(find.text('Casa compartilhada'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Navega para /settings/casa exibe HouseholdScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp('/settings/casa'));
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdScreen), findsOneWidget);
      expect(find.text('Casa compartilhada'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
