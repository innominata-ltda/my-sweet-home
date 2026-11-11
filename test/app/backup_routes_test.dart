import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';

void main() {
  group('T-I01 — Backup Routes Test', () {
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

    testWidgets('Navega para /settings/backup', (tester) async {
      await tester.pumpWidget(buildTestApp('/settings/backup'));
      await tester.pumpAndSettle();

      expect(find.text('Backup e Exportação'), findsOneWidget);
    });

    testWidgets('Navega para /settings/backup/exportar', (tester) async {
      await tester.pumpWidget(buildTestApp('/settings/backup/exportar'));
      await tester.pumpAndSettle();

      expect(find.text('Exportar Dados'), findsOneWidget);
    });

    testWidgets('Navega para /settings/backup/importar', (tester) async {
      await tester.pumpWidget(buildTestApp('/settings/backup/importar'));
      await tester.pumpAndSettle();

      expect(find.text('Importar Dados'), findsOneWidget);
    });

    testWidgets('Navega para /settings/backup/apagar-tudo', (tester) async {
      await tester.pumpWidget(buildTestApp('/settings/backup/apagar-tudo'));
      await tester.pumpAndSettle();

      expect(find.text('Apagar Tudo'), findsOneWidget);
    });
  });
}
