import 'service_item.dart';

/// Resultado de uma checagem de integridade de destino NFC/QR (S10 Central de Saúde).
class HealthCheckResult {
  final String serviceId;
  final String destinationUrl;
  final String? finalUrl;
  final ServiceHealthStatus status;
  final int? httpCode;
  final int? responseTimeMs;
  final DateTime checkedAt;
  final String? errorMessage;

  const HealthCheckResult({
    required this.serviceId,
    required this.destinationUrl,
    this.finalUrl,
    required this.status,
    this.httpCode,
    this.responseTimeMs,
    required this.checkedAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'destinationUrl': destinationUrl,
      'finalUrl': finalUrl,
      'status': status.name,
      'httpCode': httpCode,
      'responseTimeMs': responseTimeMs,
      'checkedAt': checkedAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory HealthCheckResult.fromMap(Map<String, dynamic> map) {
    ServiceHealthStatus st = ServiceHealthStatus.healthy;
    final stStr = map['status'] as String?;
    if (stStr != null) {
      st = ServiceHealthStatus.values.firstWhere(
        (e) => e.name == stStr,
        orElse: () => ServiceHealthStatus.healthy,
      );
    }

    return HealthCheckResult(
      serviceId: map['serviceId'] as String? ?? '',
      destinationUrl: map['destinationUrl'] as String? ?? '',
      finalUrl: map['finalUrl'] as String?,
      status: st,
      httpCode: (map['httpCode'] as num?)?.toInt(),
      responseTimeMs: (map['responseTimeMs'] as num?)?.toInt(),
      checkedAt: map['checkedAt'] != null
          ? DateTime.tryParse(map['checkedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
