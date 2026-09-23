import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/order_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S14 — Detalhe do Pedido (#028).
/// Discriminação de itens, valores em centavos, regras de avanço de status e controle financeiro.
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isAdvancing = false;

  String _formatStatusName(OrderStatus status) {
    return switch (status) {
      OrderStatus.orcamento => 'Orçamento',
      OrderStatus.aguardandoAprovacao => 'Aguardando Aprovação',
      OrderStatus.aprovado => 'Aprovado',
      OrderStatus.producao => 'Em Produção',
      OrderStatus.testes => 'Em Testes',
      OrderStatus.pronto => 'Pronto para Entrega',
      OrderStatus.entregue => 'Entregue',
    };
  }

  Color _getStatusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.orcamento => const Color(0xFF9E9E9E),
      OrderStatus.aguardandoAprovacao => const Color(0xFFF59E0B),
      OrderStatus.aprovado => const Color(0xFF3B82F6),
      OrderStatus.producao => const Color(0xFF8B5CF6),
      OrderStatus.testes => const Color(0xFFEC4899),
      OrderStatus.pronto => const Color(0xFF10B981),
      OrderStatus.entregue => const Color(0xFF22C55E),
    };
  }

  Future<void> _handleAdvanceStatus(OrderItem order) async {
    final nextStatus = switch (order.status) {
      OrderStatus.orcamento => OrderStatus.aguardandoAprovacao,
      OrderStatus.aguardandoAprovacao => OrderStatus.aprovado,
      OrderStatus.aprovado => OrderStatus.producao,
      OrderStatus.producao => OrderStatus.testes,
      OrderStatus.testes => OrderStatus.pronto,
      OrderStatus.pronto => OrderStatus.entregue,
      OrderStatus.entregue => null,
    };

    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pedido já foi finalizado e entregue!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdvancing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(order.id, nextStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status do pedido avançado para: ${_formatStatusName(nextStatus)}'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível avançar o pedido: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  Future<void> _handleRevertStatus(OrderItem order) async {
    final prevStatus = switch (order.status) {
      OrderStatus.entregue => OrderStatus.pronto,
      OrderStatus.pronto => OrderStatus.testes,
      OrderStatus.testes => OrderStatus.producao,
      OrderStatus.producao => OrderStatus.aprovado,
      OrderStatus.aprovado => OrderStatus.aguardandoAprovacao,
      OrderStatus.aguardandoAprovacao => OrderStatus.orcamento,
      OrderStatus.orcamento => null,
    };

    if (prevStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pedido já está na primeira etapa (Orçamento)!'),
          backgroundColor: AppColors.orangeAction,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdvancing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(order.id, prevStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status revertido para: ${_formatStatusName(prevStatus)}'),
          backgroundColor: AppColors.orangeAction,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível reverter o pedido: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  void _showSelectStatusModal(OrderItem order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF383B36),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alterar Status do Pedido',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...OrderStatus.values.map((st) {
                  final isSelected = order.status == st;
                  final color = _getStatusColor(st);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    title: Text(
                      _formatStatusName(st),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFFCCCCCC),
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.orangeAction) : null,
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      if (st != order.status) {
                        try {
                          await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, st);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status alterado para: ${_formatStatusName(st)}'),
                                backgroundColor: AppColors.greenSuccess,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao atualizar status: $e'),
                                backgroundColor: AppColors.redError,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteOrder(OrderItem order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Excluir Pedido?',
                style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente excluir o Pedido #${order.orderNumber}? Esta ação é permanente e removerá o pedido e seus registros associados.',
          style: const TextStyle(color: Color(0xFFCCCCCC), fontFamily: 'Inter', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.deleteOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #${order.orderNumber} excluído com sucesso.'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir pedido: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allOrders = ordersAsync.value ?? [];
    final allCompanies = companiesAsync.value ?? [];

    final order = allOrders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null) {
      if (ordersAsync.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.orangeAction),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Pedido não encontrado', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Pedido não localizado no banco de dados.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final company = allCompanies.where((c) => c.id == order.companyId).firstOrNull;
    final companyName = company?.tradeName ?? 'Empresa';
    final subtotalInCents = order.items.fold<int>(0, (sum, i) => sum + i.totalInCents);
    final discountInCents = subtotalInCents > order.totalInCents ? subtotalInCents - order.totalInCents : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/more');
                        }
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF222421),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pedido ${order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showSelectStatusModal(order),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.18),
                          border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatStatusName(order.status).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: _getStatusColor(order.status)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _handleDeleteOrder(order),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Card do Cliente
                    InkWell(
                      onTap: () {
                        if (order.companyId.isNotEmpty) {
                          context.push('/companies/${order.companyId}');
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.building2, color: Color(0xFF10110F), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10110F)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.notes?.isNotEmpty == true
                                        ? order.notes!
                                        : 'Criado em ${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF10110F), size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Itens do Pedido
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Itens inclusos', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 12),
                          if (order.items.isEmpty)
                            const Text('Nenhum item listado', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)))
                          else
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildItemLine(
                                    '${item.quantity}x ${item.title}',
                                    'R\$ ${(item.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                                  ),
                                )),
                          const Divider(color: Color(0xFF282A26), height: 24),
                          if (discountInCents > 0) ...[
                            _buildItemLine('Desconto', '- R\$ ${(discountInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}', isDiscount: true),
                            const SizedBox(height: 8),
                          ],
                          _buildItemLine('Total líquido', 'R\$ ${(order.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}', isTotal: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Status de Pagamento
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.creditCard, color: Color(0xFFFACC15), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pagamento: ${order.paymentStatus.name.toUpperCase()}',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final repo = ref.read(orderRepositoryProvider);
                              await repo.updatePaymentStatus(order.id, PaymentStatus.aprovado);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pagamento registrado como APROVADO com sucesso!'), backgroundColor: AppColors.greenSuccess),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text('Receber', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10110F))),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 1. Linha de Ações Operacionais: Voltar etapa + Avançar status
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: _isAdvancing || order.status == OrderStatus.orcamento
                                ? null
                                : () => _handleRevertStatus(order),
                            borderRadius: BorderRadius.circular(26),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222421),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: const Color(0xFF333532)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: order.status == OrderStatus.orcamento ? const Color(0xFF666666) : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Voltar',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: order.status == OrderStatus.orcamento ? const Color(0xFF666666) : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Material(
                            color: order.status == OrderStatus.entregue
                                ? const Color(0xFF333532)
                                : AppColors.orangeAction,
                            borderRadius: BorderRadius.circular(26),
                            child: InkWell(
                              onTap: _isAdvancing || order.status == OrderStatus.entregue
                                  ? null
                                  : () => _handleAdvanceStatus(order),
                              borderRadius: BorderRadius.circular(26),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: _isAdvancing
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Flexible(
                                            child: Text(
                                              'Avançar status',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 2. Botão Secundário: Alterar status livremente
                    InkWell(
                      onTap: () => _showSelectStatusModal(order),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1D1B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.listFilter, color: Color(0xFFCCCCCC), size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Alterar status livremente',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 3. Botão Destrutivo: Excluir pedido
                    InkWell(
                      onTap: () => _handleDeleteOrder(order),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Excluir pedido',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemLine(String title, String price, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? Colors.white : const Color(0xFF9E9E9E),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isDiscount ? const Color(0xFF22C55E) : Colors.white,
          ),
        ),
      ],
    );
  }
}
