import '../models/order_item.dart';

/// Contrato abstrato para operações de pedidos e ciclo de produção (S13, S14, RB-006, RB-007).
abstract class OrderRepository {
  /// Lista todos os pedidos com filtros opcionais
  Future<List<OrderItem>> getOrders({OrderStatus? statusFilter, String? companyId});

  /// Obtém pedido por ID
  Future<OrderItem?> getOrderById(String id);

  /// Cria um novo pedido
  Future<OrderItem> createOrder(OrderItem order);

  /// Atualiza dados de um pedido
  Future<OrderItem> updateOrder(OrderItem order);

  /// Atualiza o status do pedido (com validação de regras de negócio)
  Future<OrderItem> updateOrderStatus(String id, OrderStatus newStatus);

  /// Atualiza o status de pagamento
  Future<OrderItem> updatePaymentStatus(String id, PaymentStatus newStatus);

  /// Exclui um pedido
  Future<void> deleteOrder(String id);

  /// Stream reativa de pedidos
  Stream<List<OrderItem>> watchOrders();
}
