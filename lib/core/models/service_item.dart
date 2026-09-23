/// Status de integridade e monitoramento de saúde de um destino NFC/QR.
enum ServiceHealthStatus {
  healthy, // Saudável
  warning, // Atenção (1-2 falhas)
  error, // Erro (>=3 falhas consecutivas)
  manual, // Verificação manual requerida (bloqueio bot/antibot)
}

/// Modelo de Serviço vinculado a empresa conforme PRD_NFC_Ops_Profissional e pranchas S07/S08/S10.
class ServiceItem {
  final String id;
  final String companyId;
  final String serviceType; // google_review, instagram, cardapio, whatsapp, wifi, linktree, personalizado
  final String publicTitle; // Título de exibição (obrigatório)
  final String? internalName; // Nome interno de controle (opcional conforme PRD)
  final String destinationUrl; // Destino de gravação/QR (obrigatório)
  final String status; // ativo, inativo
  final ServiceHealthStatus healthStatus;
  final DateTime? lastCheckedAt;
  final int consecutiveFailures;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceItem({
    required this.id,
    required this.companyId,
    required this.serviceType,
    required this.publicTitle,
    this.internalName,
    required this.destinationUrl,
    this.status = 'ativo',
    this.healthStatus = ServiceHealthStatus.healthy,
    this.lastCheckedAt,
    this.consecutiveFailures = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  ServiceItem copyWith({
    String? id,
    String? companyId,
    String? serviceType,
    String? publicTitle,
    String? internalName,
    String? destinationUrl,
    String? status,
    ServiceHealthStatus? healthStatus,
    DateTime? lastCheckedAt,
    int? consecutiveFailures,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      serviceType: serviceType ?? this.serviceType,
      publicTitle: publicTitle ?? this.publicTitle,
      internalName: internalName ?? this.internalName,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      status: status ?? this.status,
      healthStatus: healthStatus ?? this.healthStatus,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'type': serviceType,
      'serviceType': serviceType,
      'customName': publicTitle,
      'publicTitle': publicTitle,
      'internalName': internalName,
      'destinationUrl': destinationUrl,
      'status': status,
      'healthStatus': healthStatus.name,
      'health': {
        'status': healthStatus.name,
        'consecutiveFailures': consecutiveFailures,
        'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      },
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'consecutiveFailures': consecutiveFailures,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map, String id) {
    ServiceHealthStatus status = ServiceHealthStatus.healthy;
    String? statusStr;
    int failures = 0;
    DateTime? lastChecked;

    if (map['health'] is Map) {
      final hMap = map['health'] as Map;
      statusStr = hMap['status'] as String?;
      failures = (hMap['consecutiveFailures'] as num?)?.toInt() ?? 0;
      if (hMap['lastCheckedAt'] != null) {
        lastChecked = DateTime.tryParse(hMap['lastCheckedAt'].toString());
      }
    } else {
      statusStr = map['healthStatus'] as String?;
      failures = (map['consecutiveFailures'] as num?)?.toInt() ?? 0;
      if (map['lastCheckedAt'] != null) {
        lastChecked = DateTime.tryParse(map['lastCheckedAt'].toString());
      }
    }

    if (statusStr != null) {
      status = ServiceHealthStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => ServiceHealthStatus.healthy,
      );
    }

    return ServiceItem(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      serviceType: map['serviceType'] as String? ?? map['type'] as String? ?? 'personalizado',
      publicTitle: map['publicTitle'] as String? ?? map['customName'] as String? ?? map['name'] as String? ?? 'Serviço',
      internalName: map['internalName'] as String?,
      destinationUrl: map['destinationUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'ativo',
      healthStatus: status,
      lastCheckedAt: lastChecked,
      consecutiveFailures: failures,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
