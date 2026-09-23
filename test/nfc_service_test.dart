import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/services/nfc_service.dart';
import 'package:nfc_ops/features/inventory/presentation/widgets/nfc_scan_modal.dart';

void main() {
  group('NfcService and NFC Flow Tests', () {
    late InMemoryDeviceRepository deviceRepo;
    late InMemoryCompanyRepository compRepo;

    setUp(() {
      deviceRepo = InMemoryDeviceRepository();
      compRepo = InMemoryCompanyRepository();
    });

    test('formatIdentifier formats byte array to uppercase hex with colons', () {
      final bytes = [0x04, 0xA2, 0x3B, 0x5C, 0x89, 0x1F];
      final formatted = NfcService.formatIdentifier(bytes);
      expect(formatted, equals('04:A2:3B:5C:89:1F'));
    });

    test('createUriRecord and parseNdefRecord encode and decode URI correctly', () {
      final record = NfcService.createUriRecord('https://instagram.com/nfcops');
      final decoded = NfcService.parseNdefRecord(record);
      expect(decoded, equals('https://instagram.com/nfcops'));
    });

    test('InMemoryDeviceRepository matches devices by nfcUid, id, or batchId regardless of formatting', () async {
      final device = DeviceItem(
        id: 'dev-nfc-test-01',
        batchId: 'ACR-9988',
        nfcUid: '04:A2:3B:5C:89:1F',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await deviceRepo.createDevice(device);

      // Match exact
      final foundExact = await deviceRepo.getDeviceByNfcUid('04:A2:3B:5C:89:1F');
      expect(foundExact, isNotNull);
      expect(foundExact!.id, equals('dev-nfc-test-01'));

      // Match lowercase without colons
      final foundClean = await deviceRepo.getDeviceByNfcUid('04a23b5c891f');
      expect(foundClean, isNotNull);
      expect(foundClean!.id, equals('dev-nfc-test-01'));

      // Match by batchId
      final foundBatch = await deviceRepo.getDeviceByNfcUid('acr-9988');
      expect(foundBatch, isNotNull);
      expect(foundBatch!.id, equals('dev-nfc-test-01'));

      // Unknown UID returns null
      final notFound = await deviceRepo.getDeviceByNfcUid('FF:FF:FF:FF:FF');
      expect(notFound, isNull);
    });

    testWidgets('NfcScanModal: scanning existing tag opens device detail and does NOT duplicate', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed an existing device with NFC UID
      final existing = DeviceItem(
        id: 'dev-existing-nfc',
        batchId: 'NFC-PLACA-01',
        nfcUid: '04:11:22:33:44:55',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await deviceRepo.createDevice(existing);

      final initialCount = (await deviceRepo.getDevices()).length;
      String? routedPath;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  NfcScanModal.show(
                    context,
                    companies: const [],
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
          GoRoute(
            path: '/inventory/:id',
            builder: (context, state) {
              routedPath = state.uri.path;
              return Scaffold(body: Text('Device Screen: ${state.pathParameters['id']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWithValue(deviceRepo),
            companyRepositoryProvider.overrideWithValue(compRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Escanear Placa NFC'), findsOneWidget);
      expect(find.text('Simular leitura de tag'), findsOneWidget);

      // Open simulator to trigger tag discovery
      await tester.tap(find.text('Simular leitura de tag'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter known UID
      await tester.enterText(find.byType(TextField).last, '04:11:22:33:44:55');
      await tester.tap(find.text('Simular'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 500));

      // Must have routed to existing device without creating duplicate
      expect(routedPath, equals('/inventory/dev-existing-nfc'));
      final finalCount = (await deviceRepo.getDevices()).length;
      expect(finalCount, equals(initialCount));
    });

    testWidgets('NfcScanModal: scanning new/unknown tag triggers onNewTagDetected callback with scanned UID', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? newTagScannedUid;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWithValue(deviceRepo),
            companyRepositoryProvider.overrideWithValue(compRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    NfcScanModal.show(
                      context,
                      companies: const [],
                      onNewTagDetected: (uid, ndefUrl) {
                        newTagScannedUid = uid;
                      },
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Open simulator and enter a brand new tag UID
      await tester.tap(find.text('Simular leitura de tag'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).last, '04:99:88:77:66:55');
      await tester.tap(find.text('Simular'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 500));

      // Callback must receive the virgin tag UID
      expect(newTagScannedUid, equals('04:99:88:77:66:55'));
    });
  });
}
