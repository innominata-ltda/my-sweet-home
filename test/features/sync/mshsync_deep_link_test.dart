import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/presentation/household_screen.dart';
import 'package:my_sweet_home/features/sync/presentation/providers/household_providers.dart';

class _MockHouseholdRepo extends Mock implements HouseholdRepository {}

void main() {
  testWidgets(
    'Navigating to /invite?data=abc redirects to HouseholdScreen and prefills join dialog',
    (tester) async {
      final repo = _MockHouseholdRepo();
      when(() => repo.watchHousehold()).thenAnswer((_) => Stream.value(null));
      when(() => repo.getHousehold()).thenAnswer((_) async => const Ok(null));
      when(() => repo.watchMembers()).thenAnswer((_) => Stream.value(const []));

      final container = ProviderContainer(
        overrides: [
          initialRouteProvider.overrideWithValue('/invite?data=abc123'),
          householdRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdScreen), findsOneWidget);
      expect(find.byKey(const Key('join_invite_code_input')), findsOneWidget);
      expect(find.text('mshsync://invite?data=abc123'), findsOneWidget);
    },
  );
}
