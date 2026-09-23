import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nfc_ops/features/health/presentation/health_center_screen.dart';
import 'package:nfc_ops/features/inventory/presentation/device_detail_screen.dart';
import 'package:nfc_ops/features/inventory/presentation/inventory_screen.dart';
import 'package:nfc_ops/features/orders/presentation/create_order_screen.dart';
import 'package:nfc_ops/features/services/presentation/edit_service_screen.dart';

import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/services/via_cep_service.dart';
import 'package:nfc_ops/features/companies/presentation/company_detail_screen.dart';
import 'package:nfc_ops/features/orders/presentation/order_detail_screen.dart';
import 'package:nfc_ops/features/qr/presentation/qr_code_screen.dart';

void main() {
  late InMemoryAuthRepository authRepo;
  late InMemoryCompanyRepository compRepo;
  late InMemoryServiceRepository srvRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryDeviceRepository devRepo;
  late InMemoryActivityRepository actRepo;

  setUp(() {
    authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);

    compRepo = InMemoryCompanyRepository();
    srvRepo = InMemoryServiceRepository();
    orderRepo = InMemoryOrderRepository();
    devRepo = InMemoryDeviceRepository();
    actRepo = InMemoryActivityRepository();
  });

  Widget createWrapper(Widget child) {
    return ProviderScope(
      overrides: [
        appModeProvider.overrideWith((ref) => AppMode.fixture),
        authRepositoryProvider.overrideWithValue(authRepo),
        companyRepositoryProvider.overrideWithValue(compRepo),
        serviceRepositoryProvider.overrideWithValue(srvRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        deviceRepositoryProvider.overrideWithValue(devRepo),
        activityRepositoryProvider.overrideWithValue(actRepo),
        healthCheckServiceProvider.overrideWithValue(MockHealthCheckService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Verification of User-Reported Fixes', () {
    testWidgets('Print 1 Fix: EditServiceScreen opens service with google_review without crashing', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      // Ensure a service with the exact singular 'google_review' exists
      final singularService = ServiceItem(
        id: 'srv-test-singular',
        companyId: 'emp-01',
        publicTitle: 'Avaliação no balcão',
        serviceType: 'google_review', // singular as in seed/firebase
        destinationUrl: 'https://g.page/r/test/review',
        healthStatus: ServiceHealthStatus.healthy,
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await srvRepo.createService(singularService);

      await tester.pumpWidget(createWrapper(const EditServiceScreen(serviceId: 'srv-test-singular')));
      await tester.pumpAndSettle();

      // Should render without Dropdown assertion error
      expect(find.text('Editar serviço'), findsOneWidget);
      expect(find.text('Salvar e testar'), findsOneWidget);
    });

    testWidgets('Print 2 Fix: DeviceDetailScreen has functional Alterar and Substituir buttons', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final testDev = DeviceItem(
        id: 'dev-test-01',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        batchId: 'NFC-00142',
        assignedCompanyId: 'emp-01',
        primaryServiceId: 'srv-001',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await devRepo.createDevice(testDev);

      await tester.pumpWidget(createWrapper(const DeviceDetailScreen(deviceId: 'dev-test-01')));
      await tester.pumpAndSettle();

      // Check Alterar and Substituir buttons exist
      expect(find.text('Alterar'), findsOneWidget);
      expect(find.text('Substituir dispositivo'), findsOneWidget);

      // Tap Alterar to open bottom modal
      await tester.tap(find.text('Alterar'));
      await tester.pumpAndSettle();

      expect(find.text('Associar Empresa & Serviço'), findsOneWidget);
      expect(find.text('Salvar vínculo'), findsOneWidget);
    });

    testWidgets('Print 3 Fix: InventoryScreen search and category filters work properly', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await devRepo.createDevice(DeviceItem(
        id: 'dev-001',
        batchId: 'LOT-2026-09A',
        deviceType: 'Placa Acrílico',
        status: DeviceStatus.disponivel,
        createdAt: SeedData.fixedDate,
        updatedAt: SeedData.fixedDate,
      ));

      await tester.pumpWidget(createWrapper(const InventoryScreen()));
      await tester.pumpAndSettle();

      // Search field and chips are rendered
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Placas'), findsOneWidget);
      expect(find.text('Cartões'), findsOneWidget);

      // Typing into search filters the items
      await tester.enterText(find.byType(TextField), 'LOT-2026-09A');
      await tester.pumpAndSettle();

      expect(find.text('LOT-2026-09A'), findsWidgets);
    });

    testWidgets('Print 4 Fix: CreateOrderScreen allows adding custom items with custom pricing', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createWrapper(const CreateOrderScreen(initialCompanyId: 'emp-01')));
      await tester.pumpAndSettle();

      expect(find.text('Novo pedido'), findsOneWidget);
      expect(find.text('Item customizado'), findsOneWidget);

      // Open add item modal
      await tester.tap(find.text('Item customizado'));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar item customizado'), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);
    });

    testWidgets('Defective Device Deletion: opens confirmation modal and removes device from repository', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final defDev = DeviceItem(
        id: 'dev-defect-01',
        deviceType: 'display_acrilico',
        status: DeviceStatus.defeito,
        batchId: 'DEF-0099',
        assignedCompanyId: null,
        primaryServiceId: null,
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await devRepo.createDevice(defDev);

      await tester.pumpWidget(createWrapper(const DeviceDetailScreen(deviceId: 'dev-defect-01')));
      await tester.pumpAndSettle();

      // Scroll to find Excluir dispositivo do estoque
      final deleteTile = find.text('Excluir dispositivo do estoque');
      await tester.scrollUntilVisible(deleteTile, 100);
      expect(deleteTile, findsOneWidget);

      // Tap to open confirmation modal
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      expect(find.text('Excluir dispositivo?'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);

      // Tap Excluir in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir'));
      await tester.pumpAndSettle();

      // Verify device was deleted from repository
      final deleted = await devRepo.getDeviceById('dev-defect-01');
      expect(deleted, isNull);
    });

    testWidgets('Dashboard: Critical problem card only exists if criticalCount > 0', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      // 1. Initially reset any seed services to healthy to test criticalCount == 0
      final allServices = await srvRepo.getAllServices();
      for (final s in allServices) {
        await srvRepo.updateHealthStatus(s.id, ServiceHealthStatus.healthy);
      }

      await tester.pumpWidget(createWrapper(const DashboardScreen()));
      await tester.pumpAndSettle();

      // No critical card rendered
      expect(find.text('Revisar agora'), findsNothing);
      expect(find.text('crítico'), findsNothing);

      // 2. Now add an error service
      final errorService = ServiceItem(
        id: 'srv-error-01',
        companyId: 'emp-01',
        publicTitle: 'Avaliação quebrada',
        serviceType: 'link',
        destinationUrl: 'https://broken.example.com',
        healthStatus: ServiceHealthStatus.error,
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await srvRepo.createService(errorService);

      await tester.pumpWidget(createWrapper(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Now critical card exists
      expect(find.text('1 problema'), findsOneWidget);
      expect(find.text('crítico'), findsOneWidget);
      expect(find.text('Revisar agora'), findsOneWidget);
    });

    testWidgets('HealthCenterScreen: Filters are interactive and problem cards have edit & delete buttons', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final errorService = ServiceItem(
        id: 'srv-problem-test',
        companyId: 'comp-002',
        publicTitle: 'Link Inexistente',
        serviceType: 'link',
        destinationUrl: 'https://404.example.com',
        healthStatus: ServiceHealthStatus.error,
        consecutiveFailures: 3,
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await srvRepo.createService(errorService);

      await tester.pumpWidget(createWrapper(const HealthCenterScreen()));
      await tester.pumpAndSettle();

      // Verify filters row exist and are interactive
      expect(find.text('Central de saúde'), findsOneWidget);
      expect(find.text('Problemas'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);

      // Tap Empresa to open filter modal
      await tester.ensureVisible(find.text('Empresa'));
      await tester.tap(find.text('Empresa'));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar por Empresa'), findsOneWidget);
      expect(find.text('Todas as empresas'), findsOneWidget);

      // Tap 'Todas as empresas' to dismiss
      await tester.tap(find.text('Todas as empresas'));
      await tester.pumpAndSettle();

      // Tap Tipo to open filter modal
      await tester.ensureVisible(find.text('Tipo'));
      await tester.tap(find.text('Tipo'));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar por Tipo de Serviço'), findsOneWidget);
      expect(find.text('Todos os tipos'), findsOneWidget);

      // Tap 'Todos os tipos' to dismiss
      await tester.tap(find.text('Todos os tipos'));
      await tester.pumpAndSettle();

      // Verify action buttons on problem card
      expect(find.text('Corrigir / Editar'), findsWidgets);
      expect(find.text('Excluir serviço'), findsWidgets);

      // Tap Excluir serviço to verify modal
      await tester.ensureVisible(find.text('Excluir serviço').first);
      await tester.tap(find.text('Excluir serviço').first);
      await tester.pumpAndSettle();

      expect(find.text('Excluir serviço?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });

    testWidgets('Print 3 Overflow Fix: QrCodeScreen does not overflow with long Instagram URL in 372x870 viewport', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      const longUrl = 'https://www.instagram.com/reis_e_alves_multimarcas_veiculos_premiums_sp/?igsh=MWFqZ2g4dGZ3a3gxbw==';
      final srv = ServiceItem(
        id: 'srv-long-instagram',
        companyId: 'emp-01',
        publicTitle: 'Instagram Reis & Alves',
        serviceType: 'instagram',
        destinationUrl: longUrl,
        healthStatus: ServiceHealthStatus.healthy,
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await srvRepo.createService(srv);

      await tester.pumpWidget(createWrapper(const QrCodeScreen(serviceId: 'srv-long-instagram')));
      await tester.pumpAndSettle();

      // Proves no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull);

      // Verify screen title and action buttons rendered cleanly
      expect(find.text('QR Code'), findsWidgets);
      expect(find.text('Destino para impressão'), findsOneWidget);
      expect(find.text('Baixar PNG'), findsOneWidget);
      expect(find.text('Copiar URL'), findsOneWidget);
    });

    testWidgets('Print 4 Fix: CompanyDetailScreen displays dynamic address and city/UF without Barueri fallback', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final mairinqueComp = Company(
        id: 'comp-mairinque',
        tradeName: 'Auto Center Mairinque',
        legalName: 'Auto Center Mairinque Ltda',
        document: '12.345.678/0001-90',
        category: 'Oficina Mecânica',
        email: 'contato@acmairinque.com.br',
        phone: '(11) 98765-4321',
        city: 'Mairinque / SP',
        notes: 'R. São Paulo, 94 - Centro, Mairinque',
        status: 'ativa',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await compRepo.createCompany(mairinqueComp);

      // Create an Instagram service with recent lastCheckedAt
      final srv = ServiceItem(
        id: 'srv-insta-mairinque',
        companyId: 'comp-mairinque',
        publicTitle: 'Instagram',
        serviceType: 'instagram',
        destinationUrl: 'https://instagram.com/acmairinque',
        healthStatus: ServiceHealthStatus.healthy,
        lastCheckedAt: DateTime.now(),
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await srvRepo.createService(srv);

      await tester.pumpWidget(createWrapper(const CompanyDetailScreen(companyId: 'comp-mairinque')));
      await tester.pumpAndSettle();

      // Header location must display Mairinque / SP and NOT Barueri
      expect(find.text('Oficina Mecânica • Mairinque / SP'), findsOneWidget);
      expect(find.textContaining('Barueri'), findsNothing);

      // Switch to Visão geral tab to verify Dados Cadastrais
      await tester.tap(find.text('Visão geral'));
      await tester.pumpAndSettle();

      expect(find.text('Dados Cadastrais'), findsOneWidget);
      expect(find.text('R. São Paulo, 94 - Centro, Mairinque'), findsOneWidget);
      expect(find.text('Mairinque / SP'), findsWidgets);
      expect(find.textContaining('Barueri'), findsNothing);

      // Switch back to Serviços tab
      await tester.tap(find.text('Serviços'));
      await tester.pumpAndSettle();

      // Verify Testar and Abrir buttons exist on the Instagram card
      expect(find.text('Testar'), findsWidgets);
      expect(find.text('Abrir'), findsWidgets);
      // Verify subtitle does not show fixed mock "13:42" or "Verificação manual"
      expect(find.text('Verificação manual'), findsNothing);
      expect(find.text('Saudável • Hoje, 13:42'), findsNothing);
    });

    testWidgets('Orders Tab in CompanyDetailScreen: displays orders list and allows creating new order', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final testComp = Company(
        id: 'comp-orders-test',
        tradeName: 'Restaurante Sabor de Casa',
        category: 'Restaurante',
        city: 'São Paulo / SP',
        status: 'ativa',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await compRepo.createCompany(testComp);

      final order1 = OrderItem(
        id: 'ord-test-01',
        companyId: 'comp-orders-test',
        orderNumber: '501',
        status: OrderStatus.producao,
        paymentStatus: PaymentStatus.aprovado,
        totalInCents: 18900,
        items: const [
          OrderItemDetail(title: 'Display Mesa Acrílico', quantity: 1, unitPriceInCents: 18900),
        ],
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await orderRepo.createOrder(order1);

      await tester.pumpWidget(createWrapper(const CompanyDetailScreen(companyId: 'comp-orders-test')));
      await tester.pumpAndSettle();

      // Drag horizontal tabs left to reveal Pedidos
      await tester.drag(find.text('Serviços').first, const Offset(-350, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pedidos'));
      await tester.pumpAndSettle();

      expect(find.text('1 pedido'), findsOneWidget);
      expect(find.text('Novo pedido'), findsOneWidget);
      expect(find.text('Pedido #501'), findsOneWidget);
      expect(find.text('PRODUÇÃO'), findsOneWidget);
      expect(find.textContaining('R\$ 189,00'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen: supports advance status, revert stage, free selection, and deletion modal', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      final order = OrderItem(
        id: 'ord-lifecycle-test',
        companyId: 'emp-01',
        orderNumber: '999',
        status: OrderStatus.aprovado,
        paymentStatus: PaymentStatus.aprovado,
        totalInCents: 25000,
        items: const [
          OrderItemDetail(title: 'Totem Balcão NFC', quantity: 1, unitPriceInCents: 25000),
        ],
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await orderRepo.createOrder(order);

      await tester.pumpWidget(createWrapper(const OrderDetailScreen(orderId: 'ord-lifecycle-test')));
      await tester.pumpAndSettle();

      // Verify controls
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Avançar status'), findsOneWidget);
      expect(find.text('Alterar status livremente'), findsOneWidget);
      expect(find.text('Excluir pedido'), findsOneWidget);

      // Advance: aprovado -> producao
      await tester.tap(find.text('Avançar status'));
      await tester.pumpAndSettle();

      final updatedToProd = await orderRepo.getOrderById('ord-lifecycle-test');
      expect(updatedToProd?.status, equals(OrderStatus.producao));

      // Revert: producao -> aprovado
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      final revertedToAprovado = await orderRepo.getOrderById('ord-lifecycle-test');
      expect(revertedToAprovado?.status, equals(OrderStatus.aprovado));

      // Open free selection modal
      await tester.tap(find.text('Alterar status livremente'));
      await tester.pumpAndSettle();

      expect(find.text('Alterar Status do Pedido'), findsOneWidget);
      expect(find.text('Em Produção'), findsOneWidget);
      expect(find.text('Pronto para Entrega'), findsOneWidget);
      expect(find.text('Entregue'), findsOneWidget);

      // Select 'Entregue'
      await tester.tap(find.text('Entregue'));
      await tester.pumpAndSettle();

      final updatedToEntregue = await orderRepo.getOrderById('ord-lifecycle-test');
      expect(updatedToEntregue?.status, equals(OrderStatus.entregue));

      // Tap Excluir pedido
      await tester.tap(find.text('Excluir pedido'));
      await tester.pumpAndSettle();

      // Verify confirmation modal
      expect(find.text('Excluir Pedido?'), findsOneWidget);
      expect(find.textContaining('Deseja realmente excluir o Pedido #999?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      // Verify order was deleted from repository
      final deleted = await orderRepo.getOrderById('ord-lifecycle-test');
      expect(deleted, isNull);
    });

    testWidgets('ViaCepService and Brazilian States list are properly initialized', (tester) async {
      expect(ViaCepService.brazilianStates.length, equals(27));
      expect(ViaCepService.brazilianStates.contains('SP'), isTrue);
      expect(ViaCepService.brazilianStates.contains('RJ'), isTrue);
      expect(ViaCepService.brazilianStates.contains('MG'), isTrue);

      // Sanitization check: invalid length returns null
      final invalidRes = await ViaCepService.fetchCep('123');
      expect(invalidRes, isNull);
    });
  });
}
