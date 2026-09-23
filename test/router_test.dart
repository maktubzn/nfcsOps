import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/router/app_router.dart';

void main() {
  group('Router & Navigation Tests', () {
    test('Router redirects unauthenticated user to /login', () {
      final router = createAppRouter(initialUser: null, enableAuthGuards: true);
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });

    test('Router redirects unauthorized (viewer/inactive) user to /login', () {
      final router = createAppRouter(
        initialUser: SeedData.unauthorizedUser,
        enableAuthGuards: true,
      );
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });

    test('Router allows authorized admin into /dashboard', () {
      final router = createAppRouter(
        initialUser: SeedData.demoAdmin,
        enableAuthGuards: true,
      );
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    });
  });
}
