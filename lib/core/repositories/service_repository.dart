import '../models/service_item.dart';

/// Contrato abstrato para operações de serviços vinculados a empresas (S07, S08, S09, S10).
abstract class ServiceRepository {
  /// Lista todos os serviços do sistema
  Future<List<ServiceItem>> getAllServices({ServiceHealthStatus? statusFilter});

  /// Lista os serviços de uma empresa específica
  Future<List<ServiceItem>> getServicesByCompanyId(String companyId);

  /// Obtém um serviço específico por ID
  Future<ServiceItem?> getServiceById(String id);

  /// Cria um novo serviço
  Future<ServiceItem> createService(ServiceItem service);

  /// Atualiza um serviço existente
  Future<ServiceItem> updateService(ServiceItem service);

  /// Exclui um serviço
  Future<void> deleteService(String id);

  /// Atualiza o status de integridade/saúde após checagem
  Future<void> updateHealthStatus(
    String id,
    ServiceHealthStatus status, {
    int consecutiveFailures = 0,
    DateTime? lastCheckedAt,
  });

  /// Stream reativa de todos os serviços
  Stream<List<ServiceItem>> watchAllServices();
}
