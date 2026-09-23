/// Status do ciclo operacional do pedido.
enum OrderStatus {
  orcamento,
  aguardandoAprovacao,
  aprovado,
  producao,
  testes,
  pronto,
  entregue,
}

/// Status de pagamento (independente do status de produção conforme PRD).
enum PaymentStatus {
  pendente,
  aprovado,
  parcelado,
  cancelado,
}

/// Detalhe de item de pedido.
class OrderItemDetail {
  final String title;
  final int quantity;
  final int unitPriceInCents;
  final String? serviceId;

  const OrderItemDetail({
    required this.title,
    required this.quantity,
    required this.unitPriceInCents,
    this.serviceId,
  });

  int get totalInCents => quantity * unitPriceInCents;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'quantity': quantity,
      'unitPriceInCents': unitPriceInCents,
      'serviceId': serviceId,
    };
  }

  factory OrderItemDetail.fromMap(Map<String, dynamic> map) {
    return OrderItemDetail(
      title: map['title'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPriceInCents: (map['unitPriceInCents'] as num?)?.toInt() ?? 0,
      serviceId: map['serviceId'] as String?,
    );
  }
}

/// Modelo de Pedido conforme PRD e pranchas S13/S14.
class OrderItem {
  final String id;
  final String companyId;
  final String orderNumber; // ex: #1042
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final int totalInCents; // Valor sempre em centavos inteiros
  final List<OrderItemDetail> items;
  final List<String> assignedDeviceIds;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderItem({
    required this.id,
    required this.companyId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalInCents,
    required this.items,
    this.assignedDeviceIds = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  OrderItem copyWith({
    String? id,
    String? companyId,
    String? orderNumber,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    int? totalInCents,
    List<OrderItemDetail>? items,
    List<String>? assignedDeviceIds,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalInCents: totalInCents ?? this.totalInCents,
      items: items ?? this.items,
      assignedDeviceIds: assignedDeviceIds ?? this.assignedDeviceIds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'orderNumber': orderNumber,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'totalInCents': totalInCents,
      'items': items.map((e) => e.toMap()).toList(),
      'assignedDeviceIds': assignedDeviceIds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map, String id) {
    OrderStatus st = OrderStatus.orcamento;
    final stStr = map['status'] as String?;
    if (stStr != null) {
      final s = stStr.toLowerCase();
      if (s == 'quote' || s == 'orcamento') {
        st = OrderStatus.orcamento;
      } else if (s == 'waiting_approval' || s == 'aguardando_aprovacao' || s == 'aguardandoaprovacao') {
        st = OrderStatus.aguardandoAprovacao;
      } else if (s == 'approved' || s == 'aprovado') {
        st = OrderStatus.aprovado;
      } else if (s == 'production' || s == 'producao') {
        st = OrderStatus.producao;
      } else if (s == 'testing' || s == 'testes') {
        st = OrderStatus.testes;
      } else if (s == 'ready' || s == 'pronto') {
        st = OrderStatus.pronto;
      } else if (s == 'delivered' || s == 'entregue') {
        st = OrderStatus.entregue;
      }
    }

    PaymentStatus pay = PaymentStatus.pendente;
    final payStr = map['paymentStatus'] as String?;
    if (payStr != null) {
      final p = payStr.toLowerCase();
      if (p == 'paid' || p == 'aprovado') {
        pay = PaymentStatus.aprovado;
      } else if (p == 'partial' || p == 'parcelado') {
        pay = PaymentStatus.parcelado;
      } else if (p == 'cancelled' || p == 'refunded' || p == 'cancelado') {
        pay = PaymentStatus.cancelado;
      } else {
        pay = PaymentStatus.pendente;
      }
    }

    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((e) => OrderItemDetail.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    int totalCents = (map['totalInCents'] as num?)?.toInt() ?? 0;
    if (totalCents == 0 && map['total'] != null) {
      totalCents = (((map['total'] as num?)?.toDouble() ?? 0) * 100).round();
    }

    String ordNum = map['orderNumber'] as String? ?? '';
    if (ordNum.isEmpty) {
      ordNum = '#${id.length > 4 ? id.substring(id.length - 4) : id}';
    }

    return OrderItem(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      orderNumber: ordNum,
      status: st,
      paymentStatus: pay,
      totalInCents: totalCents,
      items: itemsList,
      assignedDeviceIds: (map['assignedDeviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
