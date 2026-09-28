/// Posição relativa/proporcional de um QR Code em um template de placa.
/// Coordenadas e dimensões são expressas como frações (0.0 a 1.0) do tamanho da imagem base.
class QrPlacement {
  final String id;
  final String label; // Ex: "QR Principal", "QR Instagram"
  final double xPercent; // 0.0 a 1.0 (posição X relativa à largura)
  final double yPercent; // 0.0 a 1.0 (posição Y relativa à altura)
  final double wPercent; // 0.0 a 1.0 (largura relativa)
  final double hPercent; // 0.0 a 1.0 (altura relativa)
  final double rotation; // Graus (0, 90, 180, 270)
  final int pageIndex; // 0 para Página 1 (Frente), 1 para Página 2 (Verso)
  final String? relatedServiceId;
  final String? dynamicUrl;

  const QrPlacement({
    required this.id,
    this.label = 'QR Principal',
    required this.xPercent,
    required this.yPercent,
    required this.wPercent,
    required this.hPercent,
    this.rotation = 0,
    this.pageIndex = 0,
    this.relatedServiceId,
    this.dynamicUrl,
  });

  QrPlacement copyWith({
    String? id,
    String? label,
    double? xPercent,
    double? yPercent,
    double? wPercent,
    double? hPercent,
    double? rotation,
    int? pageIndex,
    String? relatedServiceId,
    String? dynamicUrl,
  }) {
    return QrPlacement(
      id: id ?? this.id,
      label: label ?? this.label,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      wPercent: wPercent ?? this.wPercent,
      hPercent: hPercent ?? this.hPercent,
      rotation: rotation ?? this.rotation,
      pageIndex: pageIndex ?? this.pageIndex,
      relatedServiceId: relatedServiceId ?? this.relatedServiceId,
      dynamicUrl: dynamicUrl ?? this.dynamicUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'wPercent': wPercent,
      'hPercent': hPercent,
      'rotation': rotation,
      'pageIndex': pageIndex,
      'relatedServiceId': relatedServiceId,
      'dynamicUrl': dynamicUrl,
    };
  }

  factory QrPlacement.fromMap(Map<String, dynamic> map) {
    return QrPlacement(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? 'QR Principal',
      xPercent: (map['xPercent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (map['yPercent'] as num?)?.toDouble() ?? 0.0,
      wPercent: (map['wPercent'] as num?)?.toDouble() ?? 0.2,
      hPercent: (map['hPercent'] as num?)?.toDouble() ?? 0.2,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      pageIndex: (map['pageIndex'] as num?)?.toInt() ?? 0,
      relatedServiceId: map['relatedServiceId'] as String?,
      dynamicUrl: map['dynamicUrl'] as String?,
    );
  }
}

/// Modelo de placa / template visual para produção de placas NFC e QR.
/// Cada template armazena a imagem base, dimensões físicas e posições dos QR Codes.
class PlateTemplate {
  final String id;
  final String name; // Ex: "TikTok 10x10", "Google Reviews Balcão"
  final String category; // 'social', 'cardapio', 'linkhub', 'multiservico', 'outro'
  final String productType; // 'placa_acrilica', 'cartao_pvc', 'adesivo', 'outro'
  final String origin; // 'internal' ou 'canva'
  final String? canvaProjectUrl; // URL direto do design no Canva
  final String? finalExportedFileUrl; // URL ou path do arquivo final gerado/anexado (PNG/PDF)
  final String? relatedServiceType; // 'google_review', 'instagram', etc.
  final String? page1ServiceType; // Serviço associado à Página 1
  final String? page2ServiceType; // Serviço associado à Página 2
  final String? page1DynamicUrl; // URL dinâmica gerada para Página 1
  final String? page2DynamicUrl; // URL dinâmica gerada para Página 2
  final double physicalWidthCm; // Largura em cm
  final double physicalHeightCm; // Altura em cm
  final String baseImageUrl; // URL no Firebase Storage
  final int baseImageWidthPx; // Resolução original da imagem
  final int baseImageHeightPx; // Resolução original da imagem
  final List<QrPlacement> qrPlacements; // Posições dos QR Codes
  final String status; // 'ativo', 'rascunho', 'arquivado'
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlateTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.productType,
    this.origin = 'internal',
    this.canvaProjectUrl,
    this.finalExportedFileUrl,
    this.relatedServiceType,
    this.page1ServiceType,
    this.page2ServiceType,
    this.page1DynamicUrl,
    this.page2DynamicUrl,
    required this.physicalWidthCm,
    required this.physicalHeightCm,
    required this.baseImageUrl,
    this.baseImageWidthPx = 0,
    this.baseImageHeightPx = 0,
    this.qrPlacements = const [],
    this.status = 'rascunho',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCanva => origin == 'canva';

  PlateTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? productType,
    String? origin,
    String? canvaProjectUrl,
    String? finalExportedFileUrl,
    String? relatedServiceType,
    String? page1ServiceType,
    String? page2ServiceType,
    String? page1DynamicUrl,
    String? page2DynamicUrl,
    double? physicalWidthCm,
    double? physicalHeightCm,
    String? baseImageUrl,
    int? baseImageWidthPx,
    int? baseImageHeightPx,
    List<QrPlacement>? qrPlacements,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlateTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      origin: origin ?? this.origin,
      canvaProjectUrl: canvaProjectUrl ?? this.canvaProjectUrl,
      finalExportedFileUrl: finalExportedFileUrl ?? this.finalExportedFileUrl,
      relatedServiceType: relatedServiceType ?? this.relatedServiceType,
      page1ServiceType: page1ServiceType ?? this.page1ServiceType,
      page2ServiceType: page2ServiceType ?? this.page2ServiceType,
      page1DynamicUrl: page1DynamicUrl ?? this.page1DynamicUrl,
      page2DynamicUrl: page2DynamicUrl ?? this.page2DynamicUrl,
      physicalWidthCm: physicalWidthCm ?? this.physicalWidthCm,
      physicalHeightCm: physicalHeightCm ?? this.physicalHeightCm,
      baseImageUrl: baseImageUrl ?? this.baseImageUrl,
      baseImageWidthPx: baseImageWidthPx ?? this.baseImageWidthPx,
      baseImageHeightPx: baseImageHeightPx ?? this.baseImageHeightPx,
      qrPlacements: qrPlacements ?? this.qrPlacements,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'productType': productType,
      'origin': origin,
      'canvaProjectUrl': canvaProjectUrl,
      'finalExportedFileUrl': finalExportedFileUrl,
      'relatedServiceType': relatedServiceType,
      'page1ServiceType': page1ServiceType,
      'page2ServiceType': page2ServiceType,
      'page1DynamicUrl': page1DynamicUrl,
      'page2DynamicUrl': page2DynamicUrl,
      'physicalWidthCm': physicalWidthCm,
      'physicalHeightCm': physicalHeightCm,
      'baseImageUrl': baseImageUrl,
      'baseImageWidthPx': baseImageWidthPx,
      'baseImageHeightPx': baseImageHeightPx,
      'qrPlacements': qrPlacements.map((q) => q.toMap()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlateTemplate.fromMap(Map<String, dynamic> map, String id) {
    final placementsList = (map['qrPlacements'] as List<dynamic>?)
            ?.map((e) => QrPlacement.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PlateTemplate(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'outro',
      productType: map['productType'] as String? ?? 'placa_acrilica',
      origin: map['origin'] as String? ?? 'internal',
      canvaProjectUrl: map['canvaProjectUrl'] as String?,
      finalExportedFileUrl: map['finalExportedFileUrl'] as String?,
      relatedServiceType: map['relatedServiceType'] as String?,
      page1ServiceType: map['page1ServiceType'] as String?,
      page2ServiceType: map['page2ServiceType'] as String?,
      page1DynamicUrl: map['page1DynamicUrl'] as String?,
      page2DynamicUrl: map['page2DynamicUrl'] as String?,
      physicalWidthCm: (map['physicalWidthCm'] as num?)?.toDouble() ?? 10.0,
      physicalHeightCm: (map['physicalHeightCm'] as num?)?.toDouble() ?? 10.0,
      baseImageUrl: map['baseImageUrl'] as String? ?? '',
      baseImageWidthPx: (map['baseImageWidthPx'] as num?)?.toInt() ?? 0,
      baseImageHeightPx: (map['baseImageHeightPx'] as num?)?.toInt() ?? 0,
      qrPlacements: placementsList,
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
