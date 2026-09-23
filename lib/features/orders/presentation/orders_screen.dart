import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/order_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';

/// Tela S13 — Lista de Pedidos do NFC Ops.
/// Gerenciamento de ordens de serviço, status de produção, pagamentos e entrega.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _statusFilter = 'todos';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final allOrders = ordersAsync.value ?? [];
    final companies = companiesAsync.value ?? [];

    final filteredOrders = allOrders.where((o) {
      if (_statusFilter == 'producao') {
        return o.status == OrderStatus.producao;
      } else if (_statusFilter == 'pronto') {
        return o.status == OrderStatus.pronto || o.status == OrderStatus.entregue;
      }
      return true;
    }).toList();

    final user = ref.watch(currentUserProvider);
    final userName = user != null && user.displayName.isNotEmpty
        ? user.displayName.split(' ').first
        : 'Gustavo';
    final userInitial = user != null && user.displayName.isNotEmpty
        ? user.displayName[0]
        : 'G';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            NfcAppHeader(
              userName: userName,
              userInitial: userInitial,
              onNotificationTap: () => context.push('/activities'),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pedidos',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${filteredOrders.length} pedido${filteredOrders.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Filtros por status
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPill('Todos', _statusFilter == 'todos', () => setState(() => _statusFilter = 'todos')),
                        const SizedBox(width: 8),
                        _buildPill('Produção', _statusFilter == 'producao', () => setState(() => _statusFilter = 'producao')),
                        const SizedBox(width: 8),
                        _buildPill('Prontos', _statusFilter == 'pronto', () => setState(() => _statusFilter = 'pronto')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // Lista de Pedidos
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161715),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Text(
                          allOrders.isEmpty
                              ? 'Nenhum pedido cadastrado no momento.\nToque no botão abaixo para criar um novo pedido.'
                              : 'Nenhum pedido encontrado para o filtro selecionado.\nToque no botão abaixo para criar um novo pedido.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final isFeatured = index == 0;
                        final orderNum = order.id.replaceAll(RegExp(r'[^0-9]'), '');
                        final displayNum = orderNum.isNotEmpty ? orderNum : order.id;
                        final comp = companies.where((c) => c.id == order.companyId).firstOrNull;
                        final compName = comp?.tradeName ?? 'Cliente';
                        final totalFormatted = (order.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',');

                        if (isFeatured) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => context.push('/orders/${order.id}'),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCream,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: AppColors.orangeAction,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.fileText, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pedido #$displayNum',
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10110F)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(compName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280))),
                                          const SizedBox(height: 4),
                                          Text(
                                            'R\$ $totalFormatted • ${order.status.name}',
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orangeAction),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Color(0xFF10110F), size: 22),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.push('/orders/${order.id}'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1D1B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF282A26)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF222421),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pedido #$displayNum',
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(compName, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E))),
                                        const SizedBox(height: 4),
                                        Text('R\$ $totalFormatted • ${order.status.name}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Botão Laranja: "+ Novo pedido"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: () => context.push('/orders/new'),
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Novo pedido',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF2C2F2A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF10110F) : Colors.white,
          ),
        ),
      ),
    );
  }
}
