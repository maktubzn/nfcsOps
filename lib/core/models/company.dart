/// Modelo de Empresa conforme schema PRD_NFC_Ops_Profissional e pranchas S03/S04/S05/S06.
class Company {
  final String id;
  final String tradeName; // Obrigatório
  final String? legalName; // Opcional
  final String category; // Obrigatório (alimentacao, saude, beleza, servicos, varejo, outros)
  final String status; // Obrigatório (ativo, prospecto, pausado, cancelado)
  final String? document; // CNPJ / CPF opcional
  final String? contactName; // Opcional
  final String? phone; // Opcional
  final String? email; // Opcional
  final String? city; // Opcional (ex: Barueri, Osasco, Cotia)
  final String? notes; // Opcional
  final int servicesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.tradeName,
    this.legalName,
    required this.category,
    required this.status,
    this.document,
    this.contactName,
    this.phone,
    this.email,
    this.city,
    this.notes,
    this.servicesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Company copyWith({
    String? id,
    String? tradeName,
    String? legalName,
    String? category,
    String? status,
    String? document,
    String? contactName,
    String? phone,
    String? email,
    String? city,
    String? notes,
    int? servicesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      tradeName: tradeName ?? this.tradeName,
      legalName: legalName ?? this.legalName,
      category: category ?? this.category,
      status: status ?? this.status,
      document: document ?? this.document,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      servicesCount: servicesCount ?? this.servicesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': tradeName,
      'tradeName': tradeName,
      'legalName': legalName,
      'category': category,
      'status': status,
      'document': document,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'city': city,
      'address': {
        'city': city,
      },
      'notes': notes,
      'serviceCount': servicesCount,
      'servicesCount': servicesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    String? cityVal = map['city'] as String?;
    if (cityVal == null && map['address'] is Map) {
      cityVal = (map['address'] as Map)['city'] as String?;
    }

    return Company(
      id: id,
      tradeName: map['tradeName'] as String? ?? map['name'] as String? ?? '',
      legalName: map['legalName'] as String?,
      category: map['category'] as String? ?? 'servicos',
      status: map['status'] as String? ?? 'active',
      document: map['document'] as String?,
      contactName: map['contactName'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      city: cityVal,
      notes: map['notes'] as String?,
      servicesCount: (map['servicesCount'] as num?)?.toInt() ??
          (map['serviceCount'] as num?)?.toInt() ??
          (map['activeServiceCount'] as num?)?.toInt() ??
          0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
