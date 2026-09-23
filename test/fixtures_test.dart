import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';

void main() {
  group('Clean Base & Fixture Invariant Tests (Seed Elimination - R1)', () {
    test('SeedData contains empty lists by default (no mocked production data)', () {
      expect(SeedData.companies, isEmpty, reason: 'SeedData.companies deve iniciar limpo');
      expect(SeedData.services, isEmpty, reason: 'SeedData.services deve iniciar limpo');
      expect(SeedData.devices, isEmpty, reason: 'SeedData.devices deve iniciar limpo');
      expect(SeedData.orders, isEmpty, reason: 'SeedData.orders deve iniciar limpo');
    });

    test('Fixed reference date and test profiles are available for testing', () {
      expect(SeedData.fixedDate, DateTime.utc(2026, 9, 20, 12, 0, 0));
      expect(SeedData.demoAdmin.isAdmin, isTrue);
      expect(SeedData.unauthorizedUser.isAuthorized, isFalse);
    });

    test('InMemory repositories initialize completely empty without initial lists', () async {
      final compRepo = InMemoryCompanyRepository();
      final srvRepo = InMemoryServiceRepository();
      final devRepo = InMemoryDeviceRepository();
      final orderRepo = InMemoryOrderRepository();
      final authRepo = InMemoryAuthRepository();

      addTearDown(() {
        compRepo.dispose();
        srvRepo.dispose();
        devRepo.dispose();
        orderRepo.dispose();
        authRepo.dispose();
      });

      expect(await compRepo.getCompanies(), isEmpty);
      expect(await srvRepo.getAllServices(), isEmpty);
      expect(await devRepo.getDevices(), isEmpty);
      expect(await orderRepo.getOrders(), isEmpty);
      expect(authRepo.currentUser, isNull);
    });
  });
}
