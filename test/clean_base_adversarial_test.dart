import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/activity_entry.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/models/user_profile.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/activities/presentation/activities_screen.dart';
import 'package:nfc_ops/features/companies/presentation/companies_screen.dart';
import 'package:nfc_ops/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nfc_ops/features/health/presentation/health_center_screen.dart';
import 'package:nfc_ops/features/inventory/presentation/inventory_screen.dart';
import 'package:nfc_ops/features/orders/presentation/orders_screen.dart';

Future<void> loadInterFonts() async {
  final fontLoader = FontLoader('Inter');
  final paths = [
    'assets/fonts/Inter-Regular.otf',
    'assets/fonts/Inter-Medium.otf',
    'assets/fonts/Inter-SemiBold.otf',
    'assets/fonts/Inter-Bold.otf',
  ];
  for (final p in paths) {
    final file = File(p);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadInterFonts();
  });

  final testDate = DateTime.utc(2026, 9, 22, 10, 0, 0);

  final adminUser = UserProfile(
    uid: 'challenger-admin-01',
    email: 'admin@nfcops.com.br',
    displayName: 'Gustavo Alves',
    role: 'admin',
    isActive: true,
    createdAt: testDate,
  );

  group('EMPIRICAL CHALLENGER: Repositories Zero-State & Adversarial Invariants', () {
    test('All InMemory repositories start with exactly 0 items without throwing', () async {
      final authRepo = InMemoryAuthRepository();
      final compRepo = InMemoryCompanyRepository();
      final srvRepo = InMemoryServiceRepository();
      final devRepo = InMemoryDeviceRepository();
      final orderRepo = InMemoryOrderRepository();
      final actRepo = InMemoryActivityRepository();

      addTearDown(() {
        authRepo.dispose();
        compRepo.dispose();
        srvRepo.dispose();
        devRepo.dispose();
        orderRepo.dispose();
        actRepo.dispose();
      });

      // Assert zero state
      expect(authRepo.currentUser, isNull);
      expect(await compRepo.getCompanies(), isEmpty);
      expect(await srvRepo.getAllServices(), isEmpty);
      expect(await devRepo.getDevices(), isEmpty);
      expect(await orderRepo.getOrders(), isEmpty);
      expect(await actRepo.getActivities(), isEmpty);

      // Assert non-existent lookups do not throw and return null/empty
      expect(await authRepo.getUserProfile('non-existent-id'), isNull);
      expect(await compRepo.getCompanyById('non-existent-id'), isNull);
      expect(await srvRepo.getServiceById('non-existent-id'), isNull);
      expect(await srvRepo.getServicesByCompanyId('non-existent-comp'), isEmpty);
      expect(await devRepo.getDeviceById('non-existent-id'), isNull);
      expect(await devRepo.getDeviceByNfcUid('non-existent-nfc'), isNull);
      expect(await devRepo.getDeviceByNfcUid(''), isNull);
      expect(await orderRepo.getOrderById('non-existent-id'), isNull);
      expect(await orderRepo.getOrders(statusFilter: OrderStatus.pronto), isEmpty);
      expect(await actRepo.getActivities(entityType: 'non-existent'), isEmpty);
    });

    test('Streams on empty repositories emit empty lists as initial events without error', () async {
      final compRepo = InMemoryCompanyRepository();
      final srvRepo = InMemoryServiceRepository();
      final devRepo = InMemoryDeviceRepository();
      final orderRepo = InMemoryOrderRepository();
      final actRepo = InMemoryActivityRepository();

      addTearDown(() {
        compRepo.dispose();
        srvRepo.dispose();
        devRepo.dispose();
        orderRepo.dispose();
        actRepo.dispose();
      });

      final initialCompanies = await compRepo.watchCompanies().first;
      expect(initialCompanies, isEmpty);

      final initialServices = await srvRepo.watchAllServices().first;
      expect(initialServices, isEmpty);

      final initialDevices = await devRepo.watchDevices().first;
      expect(initialDevices, isEmpty);

      final initialOrders = await orderRepo.watchOrders().first;
      expect(initialOrders, isEmpty);

      final initialActivities = await actRepo.watchActivities().first;
      expect(initialActivities, isEmpty);
    });

    test('Adversarial inputs: search strings with symbols, unicode, and edge cases', () async {
      final compRepo = InMemoryCompanyRepository();
      addTearDown(compRepo.dispose);

      // Search with adversarial strings on empty repo
      expect(await compRepo.getCompanies(search: "'; DROP TABLE companies;--"), isEmpty);
      expect(await compRepo.getCompanies(search: '<script>alert(1)</script>'), isEmpty);
      expect(await compRepo.getCompanies(search: '🔥🚀✨🎉'), isEmpty);
      expect(await compRepo.getCompanies(search: '   \n\t   '), isEmpty);
      expect(await compRepo.getCompanies(statusFilter: 'non-existent-status'), isEmpty);
    });

    test('First item creation in completely empty base functions perfectly', () async {
      final authRepo = InMemoryAuthRepository();
      authRepo.registerUser(adminUser);
      authRepo.simulateLogin(adminUser);

      final compRepo = InMemoryCompanyRepository(authRepository: authRepo);
      final srvRepo = InMemoryServiceRepository(authRepository: authRepo);
      final devRepo = InMemoryDeviceRepository(authRepository: authRepo);
      final orderRepo = InMemoryOrderRepository(deviceRepository: devRepo, authRepository: authRepo);
      final actRepo = InMemoryActivityRepository();

      addTearDown(() {
        authRepo.dispose();
        compRepo.dispose();
        srvRepo.dispose();
        devRepo.dispose();
        orderRepo.dispose();
        actRepo.dispose();
      });

      // 1. Create first company
      final createdComp = await compRepo.createCompany(Company(
        id: '',
        tradeName: 'Empresa Real Primeira Ltda',
        category: 'varejo',
        status: 'ativo',
        city: 'São Paulo',
        createdAt: testDate,
        updatedAt: testDate,
      ));
      expect(createdComp.id, isNotEmpty);
      expect(createdComp.tradeName, 'Empresa Real Primeira Ltda');
      expect((await compRepo.getCompanies()).length, 1);
      expect(await compRepo.getCompanyById(createdComp.id), isNotNull);

      // 2. Create first service linked to first company
      final createdSrv = await srvRepo.createService(ServiceItem(
        id: '',
        companyId: createdComp.id,
        serviceType: 'google_review',
        publicTitle: 'Avaliação Google',
        destinationUrl: 'https://g.page/r/primeira/review',
        createdAt: testDate,
        updatedAt: testDate,
      ));
      expect(createdSrv.id, isNotEmpty);
      expect((await srvRepo.getAllServices()).length, 1);
      expect((await srvRepo.getServicesByCompanyId(createdComp.id)).length, 1);

      // 3. Create first device
      final createdDev = await devRepo.createDevice(DeviceItem(
        id: '',
        batchId: 'LOT-REAL-001',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        assignedCompanyId: createdComp.id,
        primaryServiceId: createdSrv.id,
        createdAt: testDate,
        updatedAt: testDate,
      ));
      expect(createdDev.id, isNotEmpty);
      expect((await devRepo.getDevices()).length, 1);
      expect(await devRepo.getDeviceById(createdDev.id), isNotNull);

      // 4. Create first order
      final createdOrder = await orderRepo.createOrder(OrderItem(
        id: '',
        companyId: createdComp.id,
        orderNumber: '001',
        status: OrderStatus.orcamento,
        paymentStatus: PaymentStatus.pendente,
        totalInCents: 15000,
        items: const [
          OrderItemDetail(
            title: 'Display Acrílico NFC',
            quantity: 1,
            unitPriceInCents: 15000,
          )
        ],
        assignedDeviceIds: [createdDev.id],
        createdAt: testDate,
        updatedAt: testDate,
      ));
      expect(createdOrder.id, isNotEmpty);
      expect((await orderRepo.getOrders()).length, 1);
      expect(await orderRepo.getOrderById(createdOrder.id), isNotNull);

      // 5. Log first activity
      await actRepo.logActivity(ActivityEntry(
        id: 'act-001',
        actorUid: adminUser.uid,
        actorName: adminUser.displayName,
        actionType: 'create',
        entityType: 'company',
        entityId: createdComp.id,
        description: 'Primeira empresa cadastrada com sucesso.',
        timestamp: testDate,
      ));
      expect((await actRepo.getActivities()).length, 1);
    });
  });

  group('EMPIRICAL CHALLENGER: No Residual Mock Data Leaking into Screens', () {
    // Helper to pump screens with clean base providers
    Widget buildTestApp(Widget child, {InMemoryAuthRepository? authRepo}) {
      final auth = authRepo ?? InMemoryAuthRepository();
      if (auth.currentUser == null) {
        auth.registerUser(adminUser);
        auth.simulateLogin(adminUser);
      }

      return ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          authRepositoryProvider.overrideWithValue(auth),
          companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository(authRepository: auth)),
          serviceRepositoryProvider.overrideWithValue(InMemoryServiceRepository(authRepository: auth)),
          deviceRepositoryProvider.overrideWithValue(InMemoryDeviceRepository(authRepository: auth)),
          orderRepositoryProvider.overrideWith((ref) => InMemoryOrderRepository(
            deviceRepository: ref.read(deviceRepositoryProvider),
            authRepository: auth,
          )),
          activityRepositoryProvider.overrideWithValue(InMemoryActivityRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: child,
        ),
      );
    }

    testWidgets('DashboardScreen in clean base: 0 metrics, no mock companies/orders, safe empty states', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Verify no mock data names appear anywhere
      expect(find.textContaining('Padaria Bella Massa'), findsNothing);
      expect(find.textContaining('Auto Center Silva'), findsNothing);
      expect(find.textContaining('Consultoria Alpha'), findsNothing);
      expect(find.textContaining('Cardápio Digital'), findsNothing);
      expect(find.textContaining('Wi-Fi Visitantes'), findsNothing);

      // Verify clean base indicators
      expect(find.text('0'), findsWidgets); // 0 serviços, 0 empresas
      expect(find.text('serviços ativos'), findsOneWidget);
      expect(find.text('empresas'), findsOneWidget);
      expect(find.text('Nenhum serviço monitorado'), findsOneWidget);
      expect(find.text('—'), findsOneWidget); // Safe health ratio display
      expect(find.text('Nenhuma pendência operacional no momento.'), findsOneWidget);

      // Adversarial action: Tap "Testar serviços" when base has 0 services
      await tester.tap(find.text('Testar serviços'));
      await tester.pump();
      expect(find.textContaining('Nenhum serviço cadastrado para testar'), findsOneWidget);
    });

    testWidgets('CompaniesScreen in clean base: displays empty state and + Cadastrar Empresa CTA', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const CompaniesScreen()));
      await tester.pumpAndSettle();

      // No mock companies
      expect(find.textContaining('Bella Massa'), findsNothing);
      expect(find.textContaining('Silva'), findsNothing);

      // Clean base indicators
      expect(find.text('0 cadastradas'), findsOneWidget);
      expect(find.text('Nenhuma empresa cadastrada'), findsOneWidget);
      expect(find.text('+ Cadastrar Empresa'), findsOneWidget);
      expect(find.text('Nova empresa'), findsOneWidget);
    });

    testWidgets('InventoryScreen in clean base: displays empty state, no low-stock false alarm banner', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const InventoryScreen()));
      await tester.pumpAndSettle();

      // Low-stock false alarm banner MUST NOT appear in clean base
      expect(find.textContaining('Estoque baixo'), findsNothing);
      expect(find.textContaining('Adesivos: 3'), findsNothing);

      // Metrics in cards
      expect(find.text('0'), findsWidgets); // inStockCount, reservedCount
      expect(find.text('em estoque'), findsOneWidget);
      expect(find.text('reservados'), findsOneWidget);

      // Empty state text
      expect(
        find.textContaining('Nenhum dispositivo cadastrado no inventário'),
        findsOneWidget,
      );
      expect(find.text('Novo dispositivo'), findsOneWidget);
    });

    testWidgets('OrdersScreen in clean base: displays empty state and 0 pedidos', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const OrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0 pedidos'), findsOneWidget);
      expect(
        find.textContaining('Nenhum pedido cadastrado no momento'),
        findsOneWidget,
      );
      expect(find.text('Novo pedido'), findsOneWidget);
    });

    testWidgets('HealthCenterScreen in clean base: displays 0 services and 0% without throwing', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const HealthCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
      expect(find.text('0%'), findsOneWidget);
      expect(
        find.text('Nenhum serviço cadastrado para monitoramento'),
        findsOneWidget,
      );
    });

    testWidgets('ActivitiesScreen in clean base: displays empty state', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(const ActivitiesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma atividade recente'), findsOneWidget);
      expect(
        find.text('Ações operacionais aparecerão aqui em tempo real.'),
        findsOneWidget,
      );
    });
  });
}
