import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/router.dart';

void main() {
  group('initialRouteProvider', () {
    test('defaults appRouterProvider to /', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      expect(router.routeInformationProvider.value.uri.path, '/');
    });

    test('routes to /onboarding when overridden for first-run users', () {
      final container = ProviderContainer(
        overrides: [initialRouteProvider.overrideWithValue('/onboarding')],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    });
  });
}
