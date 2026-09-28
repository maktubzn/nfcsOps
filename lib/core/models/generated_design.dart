/// Arte final gerada pela composição de um template + QR Code dinâmico.
/// Vincula template, empresa, serviço, QR e dispositivo físico para rastreabilidade completa.
class GeneratedDesign {
  final String id;
  final String templateId; // Template base usado
  final String companyId; // Empresa dona da arte
  final String? serviceId; // Serviço associado
  final String qrCodeId; // QR dinâmico vinculado
  final String? deviceId; // Placa física vinculada (opcional)
  final String? exportedImageUrl; // URL da imagem final no Firebase Storage
  final String status; // 'rascunho', 'exportado', 'impresso'
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeneratedDesign({
    required this.id,
    required this.templateId,
    required this.companyId,
    this.serviceId,
    required this.qrCodeId,
    this.deviceId,
    this.exportedImageUrl,
    this.status = 'rascunho',
    required this.createdAt,
    required this.updatedAt,
  });

  GeneratedDesign copyWith({
    String? id,
    String? templateId,
    String? companyId,
    String? serviceId,
    String? qrCodeId,
    String? deviceId,
    bool clearDeviceId = false,
    String? exportedImageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeneratedDesign(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      companyId: companyId ?? this.companyId,
      serviceId: serviceId ?? this.serviceId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
      exportedImageUrl: exportedImageUrl ?? this.exportedImageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'companyId': companyId,
      'serviceId': serviceId,
      'qrCodeId': qrCodeId,
      'deviceId': deviceId,
      'exportedImageUrl': exportedImageUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GeneratedDesign.fromMap(Map<String, dynamic> map, String id) {
    return GeneratedDesign(
      id: id,
      templateId: map['templateId'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      serviceId: map['serviceId'] as String?,
      qrCodeId: map['qrCodeId'] as String? ?? '',
      deviceId: map['deviceId'] as String?,
      exportedImageUrl: map['exportedImageUrl'] as String?,
      status: map['status'] as String? ?? 'rascunho',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
