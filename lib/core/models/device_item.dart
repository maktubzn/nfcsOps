/// Status operacional do dispositivo no estoque / ciclo de produção.
enum DeviceStatus {
  disponivel, // Em estoque disponível
  emProducao, // Vinculado a pedido / em produção física
  instalado, // Entregue e em operação no cliente
  defeito, // Danificado ou reprovado no checklist
}

/// Os 8 itens obrigatórios do checklist de produção física (PRD RB-005 / Prancha 05).
class PhysicalChecklist {
  final bool visualInspection; // 1. Inspeção visual do acabamento físico
  final bool nfcChipWriting; // 2. Gravação física do chip NFC
  final bool nfcReadingTest; // 3. Leitura e validação do chip com aparelho real
  final bool qrPrintInspection; // 4. Inspeção de contraste e impressão do QR
  final bool qrScanVerification; // 5. Escaneamento do QR Code gerado
  final bool urlMatchConfirmation; // 6. Confirmação exata da URL de destino
  final bool companyVerification; // 7. Conferência do cliente correto
  final bool finalPackaging; // 8. Acabamento e embalagem final

  const PhysicalChecklist({
    this.visualInspection = false,
    this.nfcChipWriting = false,
    this.nfcReadingTest = false,
    this.qrPrintInspection = false,
    this.qrScanVerification = false,
    this.urlMatchConfirmation = false,
    this.companyVerification = false,
    this.finalPackaging = false,
  });

  bool get isComplete =>
      visualInspection &&
      nfcChipWriting &&
      nfcReadingTest &&
      qrPrintInspection &&
      qrScanVerification &&
      urlMatchConfirmation &&
      companyVerification &&
      finalPackaging;

  int get completedCount =>
      (visualInspection ? 1 : 0) +
      (nfcChipWriting ? 1 : 0) +
      (nfcReadingTest ? 1 : 0) +
      (qrPrintInspection ? 1 : 0) +
      (qrScanVerification ? 1 : 0) +
      (urlMatchConfirmation ? 1 : 0) +
      (companyVerification ? 1 : 0) +
      (finalPackaging ? 1 : 0);

  Map<String, bool> toMap() {
    return {
      'visualInspection': visualInspection,
      'nfcChipWriting': nfcChipWriting,
      'nfcReadingTest': nfcReadingTest,
      'qrPrintInspection': qrPrintInspection,
      'qrScanVerification': qrScanVerification,
      'urlMatchConfirmation': urlMatchConfirmation,
      'companyVerification': companyVerification,
      'finalPackaging': finalPackaging,
    };
  }

  factory PhysicalChecklist.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PhysicalChecklist();
    return PhysicalChecklist(
      visualInspection: map['visualInspection'] as bool? ?? false,
      nfcChipWriting: map['nfcChipWriting'] as bool? ?? false,
      nfcReadingTest: map['nfcReadingTest'] as bool? ?? false,
      qrPrintInspection: map['qrPrintInspection'] as bool? ?? false,
      qrScanVerification: map['qrScanVerification'] as bool? ?? false,
      urlMatchConfirmation: map['urlMatchConfirmation'] as bool? ?? false,
      companyVerification: map['companyVerification'] as bool? ?? false,
      finalPackaging: map['finalPackaging'] as bool? ?? false,
    );
  }
}

/// Modelo de Dispositivo / Peça física de estoque (S11, S12).
class DeviceItem {
  final String id;
  final String batchId;
  final String? nfcUid; // Identificador físico do chip NFC (ex: 04:A2:3B:5C:89:1F)
  final DateTime? nfcRecordedAt; // Data/hora da gravação física via rádio
  final String? nfcRecordedBy; // Nome ou email do operador que gravou
  final bool isNfcLocked; // Se o chip foi travado contra regravação
  final String deviceType; // display_acrilico, cartao_pvc, adesivo_resinado, chaveiro, outro
  final DeviceStatus status;
  final String? primaryServiceId;
  final String? assignedCompanyId;
  final PhysicalChecklist checklist;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceItem({
    required this.id,
    required this.batchId,
    this.nfcUid,
    this.nfcRecordedAt,
    this.nfcRecordedBy,
    this.isNfcLocked = false,
    required this.deviceType,
    required this.status,
    this.primaryServiceId,
    this.assignedCompanyId,
    this.checklist = const PhysicalChecklist(),
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DeviceItem copyWith({
    String? id,
    String? batchId,
    String? nfcUid,
    DateTime? nfcRecordedAt,
    String? nfcRecordedBy,
    bool? isNfcLocked,
    String? deviceType,
    DeviceStatus? status,
    String? primaryServiceId,
    String? assignedCompanyId,
    bool clearPrimaryService = false,
    bool clearAssignedCompany = false,
    PhysicalChecklist? checklist,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceItem(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      nfcUid: nfcUid ?? this.nfcUid,
      nfcRecordedAt: nfcRecordedAt ?? this.nfcRecordedAt,
      nfcRecordedBy: nfcRecordedBy ?? this.nfcRecordedBy,
      isNfcLocked: isNfcLocked ?? this.isNfcLocked,
      deviceType: deviceType ?? this.deviceType,
      status: status ?? this.status,
      primaryServiceId: clearPrimaryService ? null : (primaryServiceId ?? this.primaryServiceId),
      assignedCompanyId: clearAssignedCompany ? null : (assignedCompanyId ?? this.assignedCompanyId),
      checklist: checklist ?? this.checklist,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'nfcUid': nfcUid,
      'nfcRecordedAt': nfcRecordedAt?.toIso8601String(),
      'nfcRecordedBy': nfcRecordedBy,
      'isNfcLocked': isNfcLocked,
      'deviceType': deviceType,
      'status': status.name,
      'primaryServiceId': primaryServiceId,
      'assignedCompanyId': assignedCompanyId,
      'checklist': checklist.toMap(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DeviceItem.fromMap(Map<String, dynamic> map, String id) {
    DeviceStatus st = DeviceStatus.disponivel;
    final stStr = map['status'] as String?;
    if (stStr != null) {
      final s = stStr.toLowerCase();
      if (s == 'stock' || s == 'disponivel') {
        st = DeviceStatus.disponivel;
      } else if (s == 'production' || s == 'em_producao' || s == 'emproducao') {
        st = DeviceStatus.emProducao;
      } else if (s == 'ready' || s == 'installed' || s == 'instalado') {
        st = DeviceStatus.instalado;
      } else if (s == 'defective' || s == 'defeito') {
        st = DeviceStatus.defeito;
      }
    }

    final rawType = (map['deviceType'] as String?) ?? (map['physicalType'] as String?) ?? 'display_acrilico';
    String dType = rawType;
    if (rawType == 'acrylic_plate') dType = 'display_acrilico';
    if (rawType == 'pvc_card') dType = 'cartao_pvc';
    if (rawType == 'sticker') dType = 'adesivo_resinado';

    return DeviceItem(
      id: id,
      batchId: map['batchId'] as String? ?? map['internalCode'] as String? ?? '',
      nfcUid: map['nfcUid'] as String?,
      nfcRecordedAt: map['nfcRecordedAt'] != null
          ? DateTime.tryParse(map['nfcRecordedAt'].toString())
          : null,
      nfcRecordedBy: map['nfcRecordedBy'] as String?,
      isNfcLocked: map['isNfcLocked'] as bool? ?? false,
      deviceType: dType,
      status: st,
      primaryServiceId: map['primaryServiceId'] as String? ?? map['serviceId'] as String?,
      assignedCompanyId: map['assignedCompanyId'] as String? ?? map['companyId'] as String?,
      checklist: PhysicalChecklist.fromMap(map['checklist'] as Map<String, dynamic>?),
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
