import 'dart:async';
import '../models/activity_entry.dart';
import '../models/company.dart';
import '../models/device_item.dart';
import '../models/health_check_result.dart';
import '../models/order_item.dart';
import '../models/service_item.dart';
import '../models/user_profile.dart';
import '../services/health_check_service.dart';
import '../models/plate_template.dart';
import '../models/dynamic_qr_code.dart';
import '../models/generated_design.dart';
import 'template_repository.dart';
import 'qr_code_repository.dart';
import 'generated_design_repository.dart';
import 'activity_repository.dart';
import 'auth_repository.dart';
import 'company_repository.dart';
import 'device_repository.dart';
import 'order_repository.dart';
import 'service_repository.dart';

/// Implementação InMemory de AuthRepository para testes e runtime determinístico.
class InMemoryAuthRepository implements AuthRepository {
  UserProfile? _current;
  final _controller = StreamController<UserProfile?>.broadcast();
  final Map<String, UserProfile> _registeredUsers = {};

  InMemoryAuthRepository({
    UserProfile? initialUser,
    List<UserProfile>? initialUsers,
  }) {
    if (initialUsers != null) {
      for (final user in initialUsers) {
        _registeredUsers[user.uid] = user;
      }
    }
    _current = initialUser;
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  UserProfile? get currentUser => _current;

  @override
  Future<UserProfile?> signInWithGoogle({String? uid}) async {
    // Consulta o documento users/{uid} sem autopromover (FIREBASE.md seção 21)
    final targetUid = uid ?? (_current?.uid ?? 'usr-001');
    final profile = _registeredUsers[targetUid];
    if (profile == null) {
      // Usuário não provisionado em users/{uid} -> Acesso Não Autorizado
      final unprovisioned = UserProfile(
        uid: targetUid,
        email: 'novo-usuario@exemplo.com',
        displayName: 'Visitante Não Provisionado',
        role: 'viewer',
        isActive: false,
        createdAt: DateTime.now(),
      );
      _current = unprovisioned;
      _controller.add(_current);
      return _current;
    }
    _current = profile;
    _controller.add(_current);
    return _current;
  }

  /// Permite registrar perfil em users/{uid} para testes
  void registerUser(UserProfile profile) {
    _registeredUsers[profile.uid] = profile;
  }

  /// Permite injetar login de usuário não autorizado para testes negativos
  void simulateLogin(UserProfile profile) {
    _current = profile;
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return _registeredUsers[uid];
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de CompanyRepository com validação de autorização (RB-001/RB-002).
class InMemoryCompanyRepository implements CompanyRepository {
  final Map<String, Company> _companies = {};
  final _controller = StreamController<List<Company>>.broadcast();
  final DateTime Function() clock;
  final AuthRepository? authRepository;

  InMemoryCompanyRepository({
    List<Company>? initialCompanies,
    DateTime Function()? clock,
    this.authRepository,
  }) : clock = clock ?? DateTime.now {
    final list = initialCompanies ?? const [];
    for (final c in list) {
      _companies[c.id] = c;
    }
  }

  void _assertAuthorized() {
    if (authRepository != null) {
      final user = authRepository!.currentUser;
      if (user == null || !user.isAuthorized) {
        throw StateError(
          'Acesso negado: operação de escrita de empresa requer usuário autenticado com papel admin ou operator.',
        );
      }
    }
  }

  void _notify() {
    _controller.add(_companies.values.toList());
  }

  @override
  Future<List<Company>> getCompanies({String? search, String? statusFilter}) async {
    var list = _companies.values.toList();
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'todos') {
      list = list.where((c) => c.status.toLowerCase() == statusFilter.toLowerCase()).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      final digits = q.replaceAll(RegExp(r'[^\d]'), '');
      list = list.where((c) {
        final matchesPhone = digits.isNotEmpty &&
            (c.phone?.replaceAll(RegExp(r'[^\d]'), '').contains(digits) ?? false);
        return c.tradeName.toLowerCase().contains(q) ||
            (c.legalName?.toLowerCase().contains(q) ?? false) ||
            (c.category.toLowerCase().contains(q)) ||
            (c.city?.toLowerCase().contains(q) ?? false) ||
            matchesPhone ||
            (c.document?.contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Future<Company?> getCompanyById(String id) async {
    return _companies[id];
  }

  @override
  Future<Company> createCompany(Company company) async {
    _assertAuthorized();
    final now = clock();
    final newId = company.id.isEmpty ? 'emp-${DateTime.now().millisecondsSinceEpoch}' : company.id;
    final created = company.copyWith(id: newId, createdAt: now, updatedAt: now);
    _companies[newId] = created;
    _notify();
    return created;
  }

  @override
  Future<Company> updateCompany(Company company) async {
    _assertAuthorized();
    final now = clock();
    final updated = company.copyWith(updatedAt: now);
    _companies[company.id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> deleteCompany(String id) async {
    _assertAuthorized();
    _companies.remove(id);
    _notify();
  }

  @override
  Stream<List<Company>> watchCompanies() async* {
    yield _companies.values.toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de ServiceRepository.
class InMemoryServiceRepository implements ServiceRepository {
  final Map<String, ServiceItem> _services = {};
  final _controller = StreamController<List<ServiceItem>>.broadcast();
  final DateTime Function() clock;
  final AuthRepository? authRepository;

  InMemoryServiceRepository({
    List<ServiceItem>? initialServices,
    DateTime Function()? clock,
    this.authRepository,
  }) : clock = clock ?? DateTime.now {
    final list = initialServices ?? const [];
    for (final s in list) {
      _services[s.id] = s;
    }
  }

  void _assertAuthorized() {
    if (authRepository != null) {
      final user = authRepository!.currentUser;
      if (user == null || !user.isAuthorized) {
        throw StateError(
          'Acesso negado: operação de escrita de serviço requer usuário autenticado com papel admin ou operator.',
        );
      }
    }
  }

  void _notify() {
    _controller.add(_services.values.toList());
  }

  @override
  Future<List<ServiceItem>> getAllServices({ServiceHealthStatus? statusFilter}) async {
    if (statusFilter != null) {
      return _services.values.where((s) => s.healthStatus == statusFilter).toList();
    }
    return _services.values.toList();
  }

  @override
  Future<List<ServiceItem>> getServicesByCompanyId(String companyId) async {
    return _services.values.where((s) => s.companyId == companyId).toList();
  }

  @override
  Future<ServiceItem?> getServiceById(String id) async {
    return _services[id];
  }

  @override
  Future<ServiceItem> createService(ServiceItem service) async {
    _assertAuthorized();
    final now = clock();
    final newId = service.id.isEmpty ? 'srv-${DateTime.now().millisecondsSinceEpoch}' : service.id;
    final created = service.copyWith(id: newId, createdAt: now, updatedAt: now);
    _services[newId] = created;
    _notify();
    return created;
  }

  @override
  Future<ServiceItem> updateService(ServiceItem service) async {
    _assertAuthorized();
    final now = clock();
    final updated = service.copyWith(updatedAt: now);
    _services[service.id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> deleteService(String id) async {
    _assertAuthorized();
    _services.remove(id);
    _notify();
  }

  @override
  Future<void> updateHealthStatus(
    String id,
    ServiceHealthStatus status, {
    int consecutiveFailures = 0,
    DateTime? lastCheckedAt,
  }) async {
    final s = _services[id];
    if (s != null) {
      final now = clock();
      _services[id] = s.copyWith(
        healthStatus: status,
        consecutiveFailures: consecutiveFailures,
        lastCheckedAt: lastCheckedAt ?? now,
        updatedAt: now,
      );
      _notify();
    }
  }

  @override
  Stream<List<ServiceItem>> watchAllServices() async* {
    yield _services.values.toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de DeviceRepository.
class InMemoryDeviceRepository implements DeviceRepository {
  final Map<String, DeviceItem> _devices = {};
  final _controller = StreamController<List<DeviceItem>>.broadcast();
  final DateTime Function() clock;
  final AuthRepository? authRepository;

  InMemoryDeviceRepository({
    List<DeviceItem>? initialDevices,
    DateTime Function()? clock,
    this.authRepository,
  }) : clock = clock ?? DateTime.now {
    final list = initialDevices ?? const [];
    for (final d in list) {
      _devices[d.id] = d;
    }
  }

  void _assertAuthorized() {
    if (authRepository != null) {
      final user = authRepository!.currentUser;
      if (user == null || !user.isAuthorized) {
        throw StateError(
          'Acesso negado: operação de estoque requer usuário autenticado com papel admin ou operator.',
        );
      }
    }
  }

  void _notify() {
    _controller.add(_devices.values.toList());
  }

  @override
  Future<List<DeviceItem>> getDevices({DeviceStatus? statusFilter, String? companyId}) async {
    var list = _devices.values.toList();
    if (statusFilter != null) {
      list = list.where((d) => d.status == statusFilter).toList();
    }
    if (companyId != null) {
      list = list.where((d) => d.assignedCompanyId == companyId).toList();
    }
    return list;
  }

  @override
  Future<DeviceItem?> getDeviceById(String id) async {
    return _devices[id];
  }

  @override
  Future<DeviceItem?> getDeviceByNfcUid(String nfcUid) async {
    final cleanUid = nfcUid.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
    if (cleanUid.isEmpty) return null;
    return _devices.values.where((d) {
      final devNfc = (d.nfcUid ?? '').replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
      final devId = d.id.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
      final devBatch = d.batchId.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
      return devNfc == cleanUid || devId == cleanUid || devBatch == cleanUid;
    }).firstOrNull;
  }

  @override
  Future<DeviceItem> createDevice(DeviceItem device) async {
    _assertAuthorized();
    final now = clock();
    final newId = device.id.isEmpty ? 'dev-${DateTime.now().millisecondsSinceEpoch}' : device.id;
    final created = device.copyWith(id: newId, createdAt: now, updatedAt: now);
    _devices[newId] = created;
    _notify();
    return created;
  }

  @override
  Future<DeviceItem> updateDevice(DeviceItem device) async {
    _assertAuthorized();
    final now = clock();
    final updated = device.copyWith(updatedAt: now);
    _devices[device.id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<DeviceItem> updateChecklist(String id, PhysicalChecklist checklist) async {
    _assertAuthorized();
    final d = _devices[id];
    if (d == null) throw Exception('Dispositivo não encontrado: $id');
    final now = clock();
    final updated = d.copyWith(checklist: checklist, updatedAt: now);
    _devices[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<DeviceItem> updateStatus(String id, DeviceStatus status) async {
    _assertAuthorized();
    final d = _devices[id];
    if (d == null) throw Exception('Dispositivo não encontrado: $id');
    final now = clock();
    final updated = d.copyWith(status: status, updatedAt: now);
    _devices[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> deleteDevice(String id) async {
    _assertAuthorized();
    _devices.remove(id);
    _notify();
  }

  @override
  Stream<List<DeviceItem>> watchDevices() async* {
    yield _devices.values.toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de OrderRepository com validação estrita de checklist (RB-007).
class InMemoryOrderRepository implements OrderRepository {
  final Map<String, OrderItem> _orders = {};
  final _controller = StreamController<List<OrderItem>>.broadcast();
  final DateTime Function() clock;
  final DeviceRepository? deviceRepository;
  final AuthRepository? authRepository;

  InMemoryOrderRepository({
    List<OrderItem>? initialOrders,
    DateTime Function()? clock,
    this.deviceRepository,
    this.authRepository,
  }) : clock = clock ?? DateTime.now {
    final list = initialOrders ?? const [];
    for (final o in list) {
      _orders[o.id] = o;
    }
  }

  void _assertAuthorized() {
    if (authRepository != null) {
      final user = authRepository!.currentUser;
      if (user == null || !user.isAuthorized) {
        throw StateError(
          'Acesso negado: operação de pedido requer usuário autenticado com papel admin ou operator.',
        );
      }
    }
  }

  void _notify() {
    _controller.add(_orders.values.toList());
  }

  @override
  Future<List<OrderItem>> getOrders({OrderStatus? statusFilter, String? companyId}) async {
    var list = _orders.values.toList();
    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter).toList();
    }
    if (companyId != null) {
      list = list.where((o) => o.companyId == companyId).toList();
    }
    return list;
  }

  @override
  Future<OrderItem?> getOrderById(String id) async {
    return _orders[id];
  }

  @override
  Future<OrderItem> createOrder(OrderItem order) async {
    _assertAuthorized();
    final now = clock();
    final newId = order.id.isEmpty ? 'ord-${DateTime.now().millisecondsSinceEpoch}' : order.id;
    final created = order.copyWith(id: newId, createdAt: now, updatedAt: now);
    _orders[newId] = created;
    _notify();
    return created;
  }

  @override
  Future<OrderItem> updateOrder(OrderItem order) async {
    _assertAuthorized();
    final now = clock();
    final updated = order.copyWith(updatedAt: now);
    _orders[order.id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<OrderItem> updateOrderStatus(String id, OrderStatus newStatus) async {
    _assertAuthorized();
    final o = _orders[id];
    if (o == null) throw StateError('Pedido não encontrado: $id');

    // RB-007: Não permitir avanço para pronto sem conclusão do checklist em todos os dispositivos
    if (newStatus == OrderStatus.pronto) {
      if (deviceRepository != null) {
        if (o.assignedDeviceIds.isEmpty) {
          throw StateError(
            'Violação RB-007: Pedido $id não possui dispositivos físicos vinculados para validação de checklist.',
          );
        }
        for (final devId in o.assignedDeviceIds) {
          final dev = await deviceRepository!.getDeviceById(devId);
          if (dev == null) {
            throw StateError('Violação RB-007: Dispositivo vinculado $devId não encontrado.');
          }
          if (!dev.checklist.isComplete) {
            throw StateError(
              'Violação RB-007: Dispositivo $devId possui checklist físico incompleto (${dev.checklist.completedCount}/8). Todos os 8 itens são obrigatórios antes do status pronto.',
            );
          }
        }
      }
    }

    final now = clock();
    final updated = o.copyWith(status: newStatus, updatedAt: now);
    _orders[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<OrderItem> updatePaymentStatus(String id, PaymentStatus newStatus) async {
    _assertAuthorized();
    final o = _orders[id];
    if (o == null) throw StateError('Pedido não encontrado: $id');
    final now = clock();
    final updated = o.copyWith(paymentStatus: newStatus, updatedAt: now);
    _orders[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> deleteOrder(String id) async {
    _assertAuthorized();
    _orders.remove(id);
    _notify();
  }

  @override
  Stream<List<OrderItem>> watchOrders() async* {
    yield _orders.values.toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de ActivityRepository.
class InMemoryActivityRepository implements ActivityRepository {
  final List<ActivityEntry> _activities = [];
  final _controller = StreamController<List<ActivityEntry>>.broadcast();

  InMemoryActivityRepository({List<ActivityEntry>? initial}) {
    if (initial != null) {
      _activities.addAll(initial);
    }
  }

  @override
  Future<List<ActivityEntry>> getActivities({int limit = 50, String? entityType}) async {
    var list = List<ActivityEntry>.from(_activities);
    if (entityType != null) {
      list = list.where((a) => a.entityType == entityType).toList();
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
  }

  @override
  Future<void> logActivity(ActivityEntry entry) async {
    _activities.add(entry);
    _controller.add(List.unmodifiable(_activities));
  }

  @override
  Stream<List<ActivityEntry>> watchActivities({int limit = 50}) async* {
    yield _activities.take(limit).toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação de HealthCheckService com regras RB-004 e proteção contra falsa afirmação de saúde sem backend.
class MockHealthCheckService implements HealthCheckService {
  final bool hasBackendConnectivity;

  MockHealthCheckService({this.hasBackendConnectivity = false});

  @override
  Future<HealthCheckResult> checkUrl(String serviceId, String destinationUrl) async {
    // Validação estática de protocolo e proteção SSRF (FUNCTIONAL-CONTRACT.md)
    if (destinationUrl.startsWith('http://localhost') ||
        destinationUrl.startsWith('http://127.0.0.1') ||
        destinationUrl.startsWith('http://192.168.') ||
        destinationUrl.startsWith('http://10.')) {
      return HealthCheckResult(
        serviceId: serviceId,
        destinationUrl: destinationUrl,
        status: ServiceHealthStatus.error,
        errorMessage: 'Destino bloqueado: rede privada não permitida (SSRF protection).',
        checkedAt: DateTime.now(),
      );
    }

    if (destinationUrl.contains('instagram.com/sabordecasa_sp')) {
      return HealthCheckResult(
        serviceId: serviceId,
        destinationUrl: destinationUrl,
        status: ServiceHealthStatus.manual,
        httpCode: 429,
        errorMessage: 'Bloqueio de bot/loginwall detectado. Requer inspeção manual.',
        checkedAt: DateTime.now(),
      );
    }

    if (destinationUrl.contains('restaurantesabordecasa/review')) {
      return HealthCheckResult(
        serviceId: serviceId,
        destinationUrl: destinationUrl,
        status: ServiceHealthStatus.error,
        httpCode: 404,
        errorMessage: 'Página não encontrada (404 Not Found).',
        checkedAt: DateTime.now(),
      );
    }

    if (destinationUrl.contains('cardapio.sabordecasa.com.br')) {
      return HealthCheckResult(
        serviceId: serviceId,
        destinationUrl: destinationUrl,
        status: ServiceHealthStatus.warning,
        httpCode: 504,
        errorMessage: 'Gateway Timeout (504).',
        checkedAt: DateTime.now(),
      );
    }

    // Se houver conectividade com backend autorizada ativa:
    if (hasBackendConnectivity) {
      return HealthCheckResult(
        serviceId: serviceId,
        destinationUrl: destinationUrl,
        status: ServiceHealthStatus.healthy,
        httpCode: 200,
        responseTimeMs: 142,
        checkedAt: DateTime.now(),
      );
    }

    // Sem backend ativo, o contrato funcional exige NÃO alegar saúde arbitrária
    return HealthCheckResult(
      serviceId: serviceId,
      destinationUrl: destinationUrl,
      status: ServiceHealthStatus.manual,
      errorMessage:
          'Verificação remota não disponível no modo local sem backend em execução. Requer inspeção manual.',
      checkedAt: DateTime.now(),
    );
  }

  @override
  ServiceHealthStatus calculateNewStatus({
    required HealthCheckResult result,
    required int currentConsecutiveFailures,
  }) {
    if (result.status == ServiceHealthStatus.manual) {
      return ServiceHealthStatus.manual;
    }
    if (result.status == ServiceHealthStatus.healthy) {
      return ServiceHealthStatus.healthy;
    }
    // RB-004: 1 ou 2 falhas consecutivas -> Atenção; 3 ou mais -> Erro
    if (currentConsecutiveFailures + 1 >= 3) {
      return ServiceHealthStatus.error;
    }
    return ServiceHealthStatus.warning;
  }
}

/// Implementação InMemory de TemplateRepository.
class InMemoryTemplateRepository implements TemplateRepository {
  final Map<String, PlateTemplate> _templates = {};
  final _controller = StreamController<List<PlateTemplate>>.broadcast();

  InMemoryTemplateRepository({List<PlateTemplate>? initial}) {
    if (initial != null) {
      for (final t in initial) {
        _templates[t.id] = t;
      }
    }
  }

  void _notify() {
    _controller.add(_templates.values.toList());
  }

  @override
  Future<List<PlateTemplate>> getTemplates({String? category, String? status}) async {
    var list = _templates.values.toList();
    if (category != null) {
      list = list.where((t) => t.category == category).toList();
    }
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    return list;
  }

  @override
  Future<PlateTemplate?> getTemplateById(String id) async {
    return _templates[id];
  }

  @override
  Future<PlateTemplate> createTemplate(PlateTemplate template) async {
    final id = template.id.isEmpty ? 'tmpl-${DateTime.now().millisecondsSinceEpoch}' : template.id;
    final now = DateTime.now();
    final item = template.copyWith(id: id, createdAt: now, updatedAt: now);
    _templates[id] = item;
    _notify();
    return item;
  }

  @override
  Future<PlateTemplate> updateTemplate(PlateTemplate template) async {
    final now = DateTime.now();
    final item = template.copyWith(updatedAt: now);
    _templates[template.id] = item;
    _notify();
    return item;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _templates.remove(id);
    _notify();
  }

  @override
  Stream<List<PlateTemplate>> watchTemplates() async* {
    yield _templates.values.toList();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de QrCodeRepository.
class InMemoryQrCodeRepository implements QrCodeRepository {
  final Map<String, DynamicQrCode> _qrCodes = {};
  final _controller = StreamController<List<DynamicQrCode>>.broadcast();

  InMemoryQrCodeRepository({List<DynamicQrCode>? initial}) {
    if (initial != null) {
      for (final q in initial) {
        _qrCodes[q.id] = q;
      }
    }
  }

  void _notify() {
    _controller.add(_qrCodes.values.toList());
  }

  @override
  Future<List<DynamicQrCode>> getQrCodes({String? companyId}) async {
    var list = _qrCodes.values.toList();
    if (companyId != null) {
      list = list.where((q) => q.companyId == companyId).toList();
    }
    return list;
  }

  @override
  Future<DynamicQrCode?> getQrCodeById(String id) async {
    return _qrCodes[id];
  }

  @override
  Future<DynamicQrCode?> getQrCodeByShortCode(String shortCode) async {
    return _qrCodes.values
        .where((q) => q.shortCode.toLowerCase() == shortCode.toLowerCase())
        .firstOrNull;
  }

  @override
  Future<DynamicQrCode> createQrCode(DynamicQrCode qrCode) async {
    final id = qrCode.id.isEmpty ? 'qr-${DateTime.now().millisecondsSinceEpoch}' : qrCode.id;
    final now = DateTime.now();
    final item = qrCode.copyWith(id: id, createdAt: now, updatedAt: now);
    _qrCodes[id] = item;
    _notify();
    return item;
  }

  @override
  Future<DynamicQrCode> updateDestination(
    String id,
    String newDestination, {
    required String changedByUid,
    required String changedByName,
  }) async {
    final existing = _qrCodes[id];
    if (existing == null) throw StateError('QR Code não encontrado: $id');
    final now = DateTime.now();
    final newHistory = List<QrRedirectHistory>.from(existing.history)
      ..add(QrRedirectHistory(
        previousUrl: existing.currentDestination,
        newUrl: newDestination,
        changedByUid: changedByUid,
        changedByName: changedByName,
        changedAt: now,
      ));
    final updated = existing.copyWith(
      currentDestination: newDestination,
      history: newHistory,
      updatedAt: now,
    );
    _qrCodes[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> incrementScanCount(String id) async {
    final existing = _qrCodes[id];
    if (existing == null) return;
    _qrCodes[id] = existing.copyWith(scanCount: existing.scanCount + 1);
    _notify();
  }

  @override
  Future<void> deleteQrCode(String id) async {
    _qrCodes.remove(id);
    _notify();
  }

  @override
  Stream<List<DynamicQrCode>> watchQrCodes({String? companyId}) async* {
    if (companyId != null) {
      yield _qrCodes.values.where((q) => q.companyId == companyId).toList();
      yield* _controller.stream.map((list) => list.where((q) => q.companyId == companyId).toList());
    } else {
      yield _qrCodes.values.toList();
      yield* _controller.stream;
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Implementação InMemory de GeneratedDesignRepository.
class InMemoryGeneratedDesignRepository implements GeneratedDesignRepository {
  final Map<String, GeneratedDesign> _designs = {};
  final _controller = StreamController<List<GeneratedDesign>>.broadcast();

  InMemoryGeneratedDesignRepository({List<GeneratedDesign>? initial}) {
    if (initial != null) {
      for (final d in initial) {
        _designs[d.id] = d;
      }
    }
  }

  void _notify() {
    _controller.add(_designs.values.toList());
  }

  @override
  Future<List<GeneratedDesign>> getDesigns({String? companyId}) async {
    var list = _designs.values.toList();
    if (companyId != null) {
      list = list.where((d) => d.companyId == companyId).toList();
    }
    return list;
  }

  @override
  Future<GeneratedDesign?> getDesignById(String id) async {
    return _designs[id];
  }

  @override
  Future<GeneratedDesign> createDesign(GeneratedDesign design) async {
    final id = design.id.isEmpty ? 'dsg-${DateTime.now().millisecondsSinceEpoch}' : design.id;
    final now = DateTime.now();
    final item = design.copyWith(id: id, createdAt: now, updatedAt: now);
    _designs[id] = item;
    _notify();
    return item;
  }

  @override
  Future<GeneratedDesign> updateDesign(GeneratedDesign design) async {
    final now = DateTime.now();
    final item = design.copyWith(updatedAt: now);
    _designs[design.id] = item;
    _notify();
    return item;
  }

  @override
  Future<void> deleteDesign(String id) async {
    _designs.remove(id);
    _notify();
  }

  @override
  Stream<List<GeneratedDesign>> watchDesigns({String? companyId}) async* {
    if (companyId != null) {
      yield _designs.values.where((d) => d.companyId == companyId).toList();
      yield* _controller.stream.map((list) => list.where((d) => d.companyId == companyId).toList());
    } else {
      yield _designs.values.toList();
      yield* _controller.stream;
    }
  }

  void dispose() {
    _controller.close();
  }
}
