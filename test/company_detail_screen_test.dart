import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/models/activity_entry.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/companies/presentation/company_detail_screen.dart';

void main() {
  late InMemoryAuthRepository authRepo;
  late InMemoryCompanyRepository compRepo;
  late InMemoryServiceRepository srvRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryDeviceRepository devRepo;
  late InMemoryActivityRepository actRepo;

  setUp(() async {
    authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);

    compRepo = InMemoryCompanyRepository();
    srvRepo = InMemoryServiceRepository();
    orderRepo = InMemoryOrderRepository();
    devRepo = InMemoryDeviceRepository();
    actRepo = InMemoryActivityRepository();

    final testDate = DateTime(2026, 9, 20);
    await compRepo.createCompany(Company(
      id: 'emp-01',
      tradeName: 'Auto Center Silva',
      legalName: 'Silva Centro Automotivo LTDA',
      category: 'Oficina',
      status: 'ativo',
      document: '12.345.678/0001-90',
      contactName: 'Carlos Silva',
      phone: '(11) 98765-4321',
      email: 'contato@autocentersilva.com.br',
      city: 'Barueri',
      servicesCount: 4,
      createdAt: testDate,
      updatedAt: testDate,
    ));

    await srvRepo.createService(ServiceItem(
      id: 'srv-01',
      companyId: 'emp-01',
      serviceType: 'google_review',
      publicTitle: 'Google Reviews',
      destinationUrl: 'https://g.page/r/example/review',
      healthStatus: ServiceHealthStatus.healthy,
      createdAt: testDate,
      updatedAt: testDate,
    ));
    await srvRepo.createService(ServiceItem(
      id: 'srv-02',
      companyId: 'emp-01',
      serviceType: 'instagram',
      publicTitle: 'Instagram',
      destinationUrl: 'https://instagram.com/autocenter',
      healthStatus: ServiceHealthStatus.healthy,
      createdAt: testDate,
      updatedAt: testDate,
    ));
    await srvRepo.createService(ServiceItem(
      id: 'srv-03',
      companyId: 'emp-01',
      serviceType: 'localizacao',
      publicTitle: 'Localização',
      destinationUrl: 'https://maps.google.com/?q=barueri',
      healthStatus: ServiceHealthStatus.healthy,
      createdAt: testDate,
      updatedAt: testDate,
    ));
    await srvRepo.createService(ServiceItem(
      id: 'srv-04',
      companyId: 'emp-01',
      serviceType: 'whatsapp',
      publicTitle: 'Agendamento WhatsApp',
      destinationUrl: 'https://wa.me/5511987654321',
      healthStatus: ServiceHealthStatus.healthy,
      createdAt: testDate,
      updatedAt: testDate,
    ));

    await devRepo.createDevice(DeviceItem(
      id: 'dev-001',
      batchId: 'LOT-2026-09A',
      deviceType: 'Placa Acrílico',
      status: DeviceStatus.instalado,
      assignedCompanyId: 'emp-01',
      createdAt: testDate,
      updatedAt: testDate,
    ));

    await orderRepo.createOrder(OrderItem(
      id: 'ord-1043',
      orderNumber: '028',
      companyId: 'emp-01',
      status: OrderStatus.testes,
      paymentStatus: PaymentStatus.aprovado,
      totalInCents: 5000,
      items: const [OrderItemDetail(title: 'Placa NFC', quantity: 1, unitPriceInCents: 5000)],
      createdAt: testDate,
      updatedAt: testDate,
    ));

    await actRepo.logActivity(
      ActivityEntry(
        id: 'act-01',
        actionType: 'create',
        entityType: 'company',
        entityId: 'emp-01',
        description: 'Auto Center Silva cadastrada no sistema',
        actorUid: 'usr-001',
        actorName: 'Gustavo Alves',
        timestamp: testDate,
      ),
    );
  });

  Widget buildTestWidget({String companyId = 'emp-01'}) {
    return ProviderScope(
      overrides: [
        appModeProvider.overrideWith((ref) => AppMode.fixture),
        authRepositoryProvider.overrideWithValue(authRepo),
        companyRepositoryProvider.overrideWithValue(compRepo),
        serviceRepositoryProvider.overrideWithValue(srvRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        deviceRepositoryProvider.overrideWithValue(devRepo),
        activityRepositoryProvider.overrideWithValue(actRepo),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: CompanyDetailScreen(companyId: companyId),
      ),
    );
  }

  group('CompanyDetailScreen (S05) Tests', () {
    testWidgets('Renders all canonical company data and identity cards', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Card 1
      expect(find.text('Auto Center Silva'), findsOneWidget);
      expect(find.text('Oficina • Barueri / SP'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Card 2
      expect(find.text('Carlos Silva'), findsOneWidget);
      expect(find.text('Responsável'), findsOneWidget);
      expect(find.text('WhatsApp'), findsAtLeastNWidgets(1));

      // Tabs
      expect(find.text('Visão geral'), findsOneWidget);
      expect(find.text('Serviços'), findsAtLeastNWidgets(1));
      expect(find.text('Dispositivos'), findsOneWidget);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);

      // Services Section Header
      expect(find.text('4 serviços conectados'), findsOneWidget);

      // 4 Service cards
      expect(find.text('Google Reviews'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Localização'), findsOneWidget);

      // Action buttons
      expect(find.text('Adicionar serviço'), findsOneWidget);
      expect(find.text('Testar todos'), findsOneWidget);
    });

    testWidgets('Switching tabs changes content dynamically', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Visão geral
      await tester.tap(find.text('Visão geral'));
      await tester.pumpAndSettle();
      expect(find.text('Dados Cadastrais'), findsOneWidget);
      expect(find.text('Razão Social'), findsOneWidget);
      expect(find.text('CNPJ'), findsOneWidget);

      // Drag tab bar left to reveal Dispositivos, Pedidos, Histórico
      await tester.drag(find.text('Visão geral'), const Offset(-180, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dispositivos'));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.smartphone), findsWidgets);

      // Drag tab bar left to bring Pedidos into viewport
      await tester.drag(find.text('Dispositivos'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pedidos'));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.shoppingBag), findsWidgets);

      await tester.drag(find.text('Pedidos'), const Offset(-250, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('Auto Center Silva cadastrada no sistema'), findsOneWidget);

      // Drag tab bar back right and tap Serviços
      await tester.drag(find.text('Histórico'), const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Serviços'));
      await tester.pumpAndSettle();
      expect(find.text('4 serviços conectados'), findsOneWidget);
    });

    testWidgets('Alphabetical sort toggle works', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final filterBtn = find.byIcon(LucideIcons.listFilter);
      expect(filterBtn, findsOneWidget);

      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Still renders all services
      expect(find.text('Google Reviews'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('Testar todos runs health check and shows snackbar', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down so bottom buttons are well within viewport
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      final testAllBtn = find.text('Testar todos');
      expect(testAllBtn, findsOneWidget);

      await tester.tap(testAllBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('serviços testados com sucesso!'), findsOneWidget);
    });

    testWidgets('Testar individual service runs health check and shows snackbar', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down so Google Reviews "Testar" button is well within viewport
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -250));
      await tester.pumpAndSettle();

      final testBtn = find.text('Testar');
      expect(testBtn, findsWidgets);

      await tester.tap(testBtn.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('verificado:'), findsOneWidget);
    });

    testWidgets('Handles unknown company ID gracefully', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(companyId: 'comp-non-existent'));
      await tester.pumpAndSettle();

      expect(find.text('Empresa não encontrada'), findsOneWidget);
      expect(find.text('Empresa não localizada no banco de dados.'), findsOneWidget);
    });
  });
}
