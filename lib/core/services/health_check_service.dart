import '../models/health_check_result.dart';
import '../models/service_item.dart';

/// Contrato para o serviço de verificação de integridade e saúde de URLs de destino.
abstract class HealthCheckService {
  /// Executa verificação em uma URL de destino
  Future<HealthCheckResult> checkUrl(String serviceId, String destinationUrl);

  /// Determina a transição de status com base no resultado e no histórico de falhas consecutivas
  ServiceHealthStatus calculateNewStatus({
    required HealthCheckResult result,
    required int currentConsecutiveFailures,
  });
}
