/// Histórico de alterações do destino de um QR Code dinâmico.
class QrRedirectHistory {
  final String previousUrl;
  final String newUrl;
  final String changedByUid;
  final String changedByName;
  final DateTime changedAt;

  const QrRedirectHistory({
    required this.previousUrl,
    required this.newUrl,
    required this.changedByUid,
    required this.changedByName,
    required this.changedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'previousUrl': previousUrl,
      'newUrl': newUrl,
      'changedByUid': changedByUid,
      'changedByName': changedByName,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  factory QrRedirectHistory.fromMap(Map<String, dynamic> map) {
    return QrRedirectHistory(
      previousUrl: map['previousUrl'] as String? ?? '',
      newUrl: map['newUrl'] as String? ?? '',
      changedByUid: map['changedByUid'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      changedAt: map['changedAt'] != null
          ? DateTime.tryParse(map['changedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// QR Code dinâmico com URL permanente e redirect configurável.
/// A URL pública (nfcops.web.app/q/{shortCode}) nunca muda; somente o destino.
class DynamicQrCode {
  final String id;
  final String shortCode; // Código curto alfanumérico (ex: 'X4K7M2')
  final String companyId; // Empresa dona
  final String? serviceId; // Serviço associado (opcional)
  final String? templateId; // Template usado para gerar arte
  final String? deviceId; // Placa física vinculada (opcional)
  final String currentDestination; // URL de destino atual
  final String status; // 'ativo', 'inativo'
  final int scanCount; // Contador de escaneamentos
  final List<QrRedirectHistory> history; // Histórico de alterações
  final DateTime createdAt;
  final DateTime updatedAt;

  const DynamicQrCode({
    required this.id,
    required this.shortCode,
    required this.companyId,
    this.serviceId,
    this.templateId,
    this.deviceId,
    required this.currentDestination,
    this.status = 'ativo',
    this.scanCount = 0,
    this.history = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// URL pública permanente que será impressa/gravada nos QR Codes
  String get publicUrl => 'https://gusta-nfcs.web.app/q/$shortCode';

  DynamicQrCode copyWith({
    String? id,
    String? shortCode,
    String? companyId,
    String? serviceId,
    String? templateId,
    String? deviceId,
    bool clearServiceId = false,
    bool clearTemplateId = false,
    bool clearDeviceId = false,
    String? currentDestination,
    String? status,
    int? scanCount,
    List<QrRedirectHistory>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DynamicQrCode(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      companyId: companyId ?? this.companyId,
      serviceId: clearServiceId ? null : (serviceId ?? this.serviceId),
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
      currentDestination: currentDestination ?? this.currentDestination,
      status: status ?? this.status,
      scanCount: scanCount ?? this.scanCount,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shortCode': shortCode,
      'companyId': companyId,
      'serviceId': serviceId,
      'templateId': templateId,
      'deviceId': deviceId,
      'currentDestination': currentDestination,
      'publicUrl': publicUrl,
      'status': status,
      'scanCount': scanCount,
      'history': history.map((h) => h.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DynamicQrCode.fromMap(Map<String, dynamic> map, String id) {
    final histList = (map['history'] as List<dynamic>?)
            ?.map((e) => QrRedirectHistory.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DynamicQrCode(
      id: id,
      shortCode: map['shortCode'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      serviceId: map['serviceId'] as String?,
      templateId: map['templateId'] as String?,
      deviceId: map['deviceId'] as String?,
      currentDestination: map['currentDestination'] as String? ?? '',
      status: map['status'] as String? ?? 'ativo',
      scanCount: (map['scanCount'] as num?)?.toInt() ?? 0,
      history: histList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
