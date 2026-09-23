import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/models/user_profile.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';

void main() {
  group('InMemory Repositories & Business Logic Tests', () {
    late InMemoryAuthRepository authRepo;
    late InMemoryCompanyRepository companyRepo;
    late InMemoryServiceRepository serviceRepo;
    late InMemoryDeviceRepository deviceRepo;
    late InMemoryOrderRepository orderRepo;
    late MockHealthCheckService healthService;

    final testDate = DateTime.utc(2026, 9, 20, 12, 0, 0);

    final testAdmin = UserProfile(
      uid: 'usr-001',
      email: 'admin@nfcops.com.br',
      displayName: 'Gustavo Alves',
      role: 'admin',
      isActive: true,
      createdAt: SeedData.fixedDate,
    );

    setUp(() {
      authRepo = InMemoryAuthRepository();
      authRepo.registerUser(testAdmin);
      authRepo.simulateLogin(testAdmin);

      companyRepo = InMemoryCompanyRepository(authRepository: authRepo);
      serviceRepo = InMemoryServiceRepository(authRepository: authRepo);
      deviceRepo = InMemoryDeviceRepository(authRepository: authRepo);
      orderRepo = InMemoryOrderRepository(
        deviceRepository: deviceRepo,
        authRepository: authRepo,
      );
      healthService = MockHealthCheckService(hasBackendConnectivity: false);
    });

    tearDown(() {
      authRepo.dispose();
      companyRepo.dispose();
      serviceRepo.dispose();
      deviceRepo.dispose();
      orderRepo.dispose();
    });

    test('AuthRepository handles login, logout, and unauthorized user blocking', () async {
      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);

      final logged = await authRepo.signInWithGoogle();
      expect(logged, isNotNull);
      expect(logged!.isAdmin, isTrue);
      expect(authRepo.currentUser, isNotNull);

      // RB-002: Usuário inativo / sem papel autorizado
      authRepo.simulateLogin(SeedData.unauthorizedUser);
      expect(authRepo.currentUser!.isAuthorized, isFalse);

      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
    });

    test('AuthRepository does not auto-promote unprovisioned users to admin (F-02)', () async {
      await authRepo.signOut();
      final unprovisioned = await authRepo.signInWithGoogle(uid: 'unregistered-uid-999');
      expect(unprovisioned, isNotNull);
      expect(unprovisioned!.isAdmin, isFalse);
      expect(unprovisioned.isAuthorized, isFalse);
      expect(unprovisioned.role, 'viewer');
    });

    test('CompanyRepository mutation requires authorized user (F-04)', () async {
      // Simula usuário deslogado / não autorizado
      authRepo.simulateLogin(SeedData.unauthorizedUser);

      expect(
        () => companyRepo.createCompany(Company(
          id: '',
          tradeName: 'Empresa Invalida',
          category: 'varejo',
          status: 'prospecto',
          createdAt: testDate,
          updatedAt: testDate,
        )),
        throwsA(isA<StateError>()),
      );

      expect(
        () => companyRepo.deleteCompany('emp-01'),
        throwsA(isA<StateError>()),
      );
    });

    test('CompanyRepository starts clean, and supports search, create, update, delete for authorized user', () async {
      final initial = await companyRepo.getCompanies();
      expect(initial, isEmpty, reason: 'Base inicia limpa por padrão');

      // Inserir fixtures pontuais para teste de busca e filtros
      await companyRepo.createCompany(Company(
        id: 'emp-01',
        tradeName: 'Padaria Bella Massa',
        category: 'Padaria',
        status: 'ativo',
        city: 'São Paulo',
        createdAt: testDate,
        updatedAt: testDate,
      ));
      await companyRepo.createCompany(Company(
        id: 'emp-02',
        tradeName: 'Auto Center Silva',
        category: 'Oficina',
        status: 'ativo',
        city: 'Barueri',
        createdAt: testDate,
        updatedAt: testDate,
      ));
      await companyRepo.createCompany(Company(
        id: 'emp-03',
        tradeName: 'Consultoria Alpha',
        category: 'Serviços',
        status: 'lead',
        city: 'Osasco',
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final all = await companyRepo.getCompanies();
      expect(all.length, 3);

      final active = await companyRepo.getCompanies(statusFilter: 'ativo');
      expect(active.length, 2);

      final searchMassa = await companyRepo.getCompanies(search: 'Bella Massa');
      expect(searchMassa.length, 1);
      expect(searchMassa.first.tradeName, 'Padaria Bella Massa');

      // Criação de nova empresa
      final created = await companyRepo.createCompany(Company(
        id: '',
        tradeName: 'Nova Empresa Teste',
        category: 'varejo',
        status: 'prospecto',
        createdAt: testDate,
        updatedAt: testDate,
      ));
      expect(created.id, isNotEmpty);

      final found = await companyRepo.getCompanyById(created.id);
      expect(found, isNotNull);
      expect(found!.tradeName, 'Nova Empresa Teste');

      // Atualização
      final updated = await companyRepo.updateCompany(found.copyWith(status: 'ativo'));
      expect(updated.status, 'ativo');

      // Remoção
      await companyRepo.deleteCompany(created.id);
      final deleted = await companyRepo.getCompanyById(created.id);
      expect(deleted, isNull);
    });

    test('ServiceRepository starts clean, supports filtering by health status and updateHealthStatus', () async {
      final initial = await serviceRepo.getAllServices();
      expect(initial, isEmpty, reason: 'Base de serviços inicia limpa');

      await serviceRepo.createService(ServiceItem(
        id: 'srv-01',
        companyId: 'emp-01',
        publicTitle: 'Cardápio Digital',
        serviceType: 'cardapio',
        destinationUrl: 'https://bellamassa.com.br/menu',
        healthStatus: ServiceHealthStatus.healthy,
        createdAt: testDate,
        updatedAt: testDate,
      ));
      await serviceRepo.createService(ServiceItem(
        id: 'srv-02',
        companyId: 'emp-01',
        publicTitle: 'Wi-Fi Visitantes',
        serviceType: 'wifi',
        destinationUrl: 'https://bellamassa.com.br/wifi',
        healthStatus: ServiceHealthStatus.warning,
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final all = await serviceRepo.getAllServices();
      expect(all.length, 2);

      final healthy = await serviceRepo.getAllServices(statusFilter: ServiceHealthStatus.healthy);
      expect(healthy.length, 1);

      final warning = await serviceRepo.getAllServices(statusFilter: ServiceHealthStatus.warning);
      expect(warning.length, 1);

      // Atualiza saúde
      await serviceRepo.updateHealthStatus(
        'srv-01',
        ServiceHealthStatus.warning,
        consecutiveFailures: 1,
      );
      final updatedSrv = await serviceRepo.getServiceById('srv-01');
      expect(updatedSrv!.healthStatus, ServiceHealthStatus.warning);
      expect(updatedSrv.consecutiveFailures, 1);
    });

    test('DeviceRepository starts clean, supports checklist update and status transition', () async {
      final initial = await deviceRepo.getDevices();
      expect(initial, isEmpty, reason: 'Base de dispositivos inicia limpa');

      await deviceRepo.createDevice(DeviceItem(
        id: 'dev-003',
        batchId: 'LOT-2026-09C',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final dev = await deviceRepo.getDeviceById('dev-003');
      expect(dev, isNotNull);
      expect(dev!.checklist.isComplete, isFalse);

      // Atualiza checklist com todos os 8 itens
      const fullChecklist = PhysicalChecklist(
        visualInspection: true,
        nfcChipWriting: true,
        nfcReadingTest: true,
        qrPrintInspection: true,
        qrScanVerification: true,
        urlMatchConfirmation: true,
        companyVerification: true,
        finalPackaging: true,
      );

      final updatedDev = await deviceRepo.updateChecklist('dev-003', fullChecklist);
      expect(updatedDev.checklist.isComplete, isTrue);

      final withNewStatus = await deviceRepo.updateStatus('dev-003', DeviceStatus.instalado);
      expect(withNewStatus.status, DeviceStatus.instalado);
    });

    test('OrderRepository enforces checklist completion before transitioning to pronto (F-01 / RB-007)', () async {
      // Cria dispositivo vinculado com checklist incompleto
      await deviceRepo.createDevice(DeviceItem(
        id: 'dev-002',
        batchId: 'LOT-2026-09B',
        deviceType: 'display_acrilico',
        status: DeviceStatus.disponivel,
        checklist: const PhysicalChecklist(
          visualInspection: true,
          nfcChipWriting: true,
          nfcReadingTest: true,
          qrPrintInspection: true,
        ),
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
        assignedDeviceIds: const ['dev-002'],
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final dev2 = await deviceRepo.getDeviceById('dev-002');
      expect(dev2!.checklist.isComplete, isFalse);

      // Transição para pronto DEVE falhar com StateError
      expect(
        () => orderRepo.updateOrderStatus('ord-1043', OrderStatus.pronto),
        throwsA(isA<StateError>()),
      );

      // Completar todos os 8 itens no dispositivo vinculado
      const fullCheck = PhysicalChecklist(
        visualInspection: true,
        nfcChipWriting: true,
        nfcReadingTest: true,
        qrPrintInspection: true,
        qrScanVerification: true,
        urlMatchConfirmation: true,
        companyVerification: true,
        finalPackaging: true,
      );
      await deviceRepo.updateChecklist('dev-002', fullCheck);

      // Agora a transição para pronto DEVE ter sucesso
      final readyOrder = await orderRepo.updateOrderStatus('ord-1043', OrderStatus.pronto);
      expect(readyOrder.status, OrderStatus.pronto);
    });

    test('OrderRepository status update and payment transition', () async {
      await orderRepo.createOrder(OrderItem(
        id: 'ord-1044',
        orderNumber: '029',
        companyId: 'emp-01',
        status: OrderStatus.orcamento,
        paymentStatus: PaymentStatus.pendente,
        totalInCents: 5000,
        items: const [OrderItemDetail(title: 'Cartão NFC', quantity: 2, unitPriceInCents: 2500)],
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final order = await orderRepo.getOrderById('ord-1044');
      expect(order, isNotNull);
      expect(order!.status, OrderStatus.orcamento);

      final updatedOrder = await orderRepo.updateOrderStatus('ord-1044', OrderStatus.aguardandoAprovacao);
      expect(updatedOrder.status, OrderStatus.aguardandoAprovacao);

      final paidOrder = await orderRepo.updatePaymentStatus('ord-1044', PaymentStatus.aprovado);
      expect(paidOrder.paymentStatus, PaymentStatus.aprovado);
    });

    test('HealthCheckService evaluates SSRF, botwall, and prevents false health claim without backend (F-03 / RB-004)', () async {
      // Teste de bloqueio de rede privada / SSRF
      final ssrf = await healthService.checkUrl('s-test', 'http://192.168.1.1/admin');
      expect(ssrf.status, ServiceHealthStatus.error);
      expect(ssrf.errorMessage, contains('SSRF'));

      // Teste de bloqueio antibot -> Verificação manual
      final manual = await healthService.checkUrl('srv-47', 'https://instagram.com/sabordecasa_sp');
      expect(manual.status, ServiceHealthStatus.manual);
      expect(
        healthService.calculateNewStatus(result: manual, currentConsecutiveFailures: 0),
        ServiceHealthStatus.manual,
      );

      // Teste sem conectividade de backend ativa: URL arbitrária NÃO afirma saúde falsa
      final unverified = await healthService.checkUrl('srv-99', 'https://site-aleatorio.com');
      expect(unverified.status, ServiceHealthStatus.manual);
      expect(unverified.errorMessage, contains('sem backend'));

      // Teste com conectividade de backend habilitada
      final activeHealthService = MockHealthCheckService(hasBackendConnectivity: true);
      final verified = await activeHealthService.checkUrl('srv-99', 'https://site-aleatorio.com');
      expect(verified.status, ServiceHealthStatus.healthy);
      expect(verified.httpCode, 200);
    });
  });
}
