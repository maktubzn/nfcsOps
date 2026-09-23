import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/core/widgets/nfc_bottom_nav_bar.dart';
import 'package:nfc_ops/features/dashboard/presentation/dashboard_screen.dart';

Future<void> loadAllFonts() async {
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

  final lucideFile = File('assets/fonts/lucide.ttf');
  if (lucideFile.existsSync()) {
    final bytes = lucideFile.readAsBytesSync();
    final lucide1 = FontLoader('packages/lucide_icons_flutter/Lucide');
    lucide1.addFont(Future.value(ByteData.view(bytes.buffer)));
    await lucide1.load();

    final lucide2 = FontLoader('Lucide');
    lucide2.addFont(Future.value(ByteData.view(bytes.buffer)));
    await lucide2.load();
  }

  final matFile = File('assets/fonts/MaterialIcons-Regular.otf');
  if (matFile.existsSync()) {
    final bytes = matFile.readAsBytesSync();
    final matLoader = FontLoader('MaterialIcons');
    matLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await matLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAuthRepository authRepo;
  late InMemoryCompanyRepository compRepo;
  late InMemoryServiceRepository srvRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryDeviceRepository devRepo;

  setUpAll(() async {
    await loadAllFonts();
  });

  setUp(() {
    authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);

    compRepo = InMemoryCompanyRepository();
    srvRepo = InMemoryServiceRepository();
    orderRepo = InMemoryOrderRepository();
    devRepo = InMemoryDeviceRepository();
  });

  Widget createTestWidget({GoRouter? router}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        companyRepositoryProvider.overrideWithValue(compRepo),
        serviceRepositoryProvider.overrideWithValue(srvRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        deviceRepositoryProvider.overrideWithValue(devRepo),
        healthCheckServiceProvider.overrideWithValue(MockHealthCheckService(hasBackendConnectivity: true)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: const DashboardScreen(),
          bottomNavigationBar: NfcBottomNavBar(
            currentIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
  }

  group('DashboardScreen (S02)', () {
    testWidgets('renders clean base empty state (0 companies, 0 services)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Header greeting and name
      expect(find.text('Bom dia,'), findsOneWidget);
      expect(find.text('Gustavo'), findsOneWidget);

      // Main title
      expect(find.text('Tudo sob controle?'), findsOneWidget);

      // Split metric cards start at 0
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('serviços ativos'), findsOneWidget);
      expect(find.text('empresas'), findsOneWidget);

      // Status card shows neutral state
      expect(find.text('Status geral dos serviços'), findsOneWidget);
      expect(find.text('Nenhum serviço monitorado'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      // Pendências empty state
      expect(find.text('Pendências'), findsOneWidget);
      expect(find.text('Nenhuma pendência operacional no momento.'), findsOneWidget);

      // Primary action button
      expect(find.text('Testar serviços'), findsOneWidget);

      // Bottom nav bar items
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Empresas'), findsOneWidget);
      expect(find.text('Estoque'), findsOneWidget);
      expect(find.text('Mais'), findsOneWidget);
    });

    testWidgets('validates empty services when Testar serviços is tapped on clean base', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final testButton = find.text('Testar serviços');
      expect(testButton, findsOneWidget);

      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Nenhum serviço cadastrado para testar'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders populated state when companies, services and orders are present', (tester) async {
      final testDate = DateTime.utc(2026, 9, 20);

      // Injeta fixtures pontuais para validar renderização dinâmica
      await compRepo.createCompany(Company(
        id: 'emp-01',
        tradeName: 'Auto Center Silva',
        category: 'Oficina',
        status: 'ativo',
        createdAt: testDate,
        updatedAt: testDate,
      ));

      await srvRepo.createService(ServiceItem(
        id: 'srv-01',
        companyId: 'emp-01',
        publicTitle: 'Cardápio Digital',
        serviceType: 'cardapio',
        destinationUrl: 'https://example.com/menu',
        healthStatus: ServiceHealthStatus.healthy,
        createdAt: testDate,
        updatedAt: testDate,
      ));

      await srvRepo.createService(ServiceItem(
        id: 'srv-02',
        companyId: 'emp-01',
        publicTitle: 'Wi-Fi',
        serviceType: 'wifi',
        destinationUrl: 'https://example.com/wifi',
        healthStatus: ServiceHealthStatus.warning,
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

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Métricas
      expect(find.text('2'), findsWidgets); // 2 serviços ativos / contagem
      expect(find.text('1'), findsWidgets); // 1 empresa / contagens
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('saudáveis'), findsOneWidget);
      expect(find.text('atenção'), findsOneWidget);

      // Pendência
      expect(find.text('Pedido #028'), findsOneWidget);
      expect(find.text('Aguardando testes'), findsOneWidget);
    });

    testWidgets('executes real health check when Testar serviços is tapped with services', (tester) async {
      final testDate = DateTime.utc(2026, 9, 20);
      await srvRepo.createService(ServiceItem(
        id: 'srv-01',
        companyId: 'emp-01',
        publicTitle: 'Cardápio',
        serviceType: 'cardapio',
        destinationUrl: 'https://example.com/cardapio',
        healthStatus: ServiceHealthStatus.healthy,
        createdAt: testDate,
        updatedAt: testDate,
      ));

      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final testButton = find.text('Testar serviços');
      expect(testButton, findsOneWidget);

      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('serviços verificados com sucesso'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('handles different viewports without overflow', (tester) async {
      // 360x780 (Compact Android)
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 372x870 (Canonical Figma)
      tester.view.physicalSize = const Size(372, 870);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 390x844 (iPhone 14)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 412x915 (Galaxy S24+ / Pixel)
      tester.view.physicalSize = const Size(412, 915);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
