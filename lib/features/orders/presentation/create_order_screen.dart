import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/order_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Item em edição na tela de criação de pedidos.
class _OrderItemDraft {
  String title;
  int quantity;
  double unitPrice; // em Reais (R$)

  _OrderItemDraft({
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
  int get unitPriceInCents => (unitPrice * 100).round();
  int get subtotalInCents => (subtotal * 100).round();
}

/// Tela A03 — Cadastro de Novo Pedido Comercial do NFC Ops com Autonomia Total.
class CreateOrderScreen extends ConsumerStatefulWidget {
  final String? initialCompanyId;
  const CreateOrderScreen({super.key, this.initialCompanyId});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  String? _selectedCompanyId;
  late List<_OrderItemDraft> _items;
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.initialCompanyId;
    _items = [];
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get _discount => double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0.0;
  double get _total => (_subtotal - _discount) > 0 ? (_subtotal - _discount) : 0.0;

  void _addItem(String title, double unitPrice) {
    setState(() {
      _items.add(_OrderItemDraft(title: title, quantity: 1, unitPrice: unitPrice));
    });
  }

  void _showAddCustomItemDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1D1B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Adicionar item customizado',
            style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Descrição / Nome do item *', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9E9E9E), fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'Ex: Combo Software + Placa NFC',
                    hintStyle: const TextStyle(color: Color(0xFF555953)),
                    filled: true,
                    fillColor: const Color(0xFF141513),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Valor unitário (R\$) *', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9E9E9E), fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: '180,00',
                    hintStyle: const TextStyle(color: Color(0xFF555953)),
                    filled: true,
                    fillColor: const Color(0xFF141513),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Quantidade', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9E9E9E), fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: '1',
                    hintStyle: const TextStyle(color: Color(0xFF555953)),
                    filled: true,
                    fillColor: const Color(0xFF141513),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                if (title.isEmpty) return;

                setState(() {
                  _items.add(_OrderItemDraft(title: title, quantity: qty > 0 ? qty : 1, unitPrice: price));
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCreateOrder() async {
    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma empresa vinculada antes de criar o pedido!')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item ao pedido!')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);

      final totalInCents = (_total * 100).round();
      final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
      final orderNumber = '#${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final orderDetails = _items.map((i) {
        return OrderItemDetail(
          title: i.title,
          quantity: i.quantity,
          unitPriceInCents: i.unitPriceInCents,
        );
      }).toList();

      final newOrder = OrderItem(
        id: orderId,
        companyId: _selectedCompanyId!,
        orderNumber: orderNumber,
        status: OrderStatus.orcamento,
        paymentStatus: PaymentStatus.pendente,
        totalInCents: totalInCents,
        items: orderDetails,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'Criado via NFC Ops',
        assignedDeviceIds: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createOrder(newOrder);

      // Log de atividade
      await actRepo.logActivity(ActivityEntry(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        actorUid: 'usr-001',
        actorName: 'Operador NFC Ops',
        actionType: 'create',
        entityType: 'order',
        entityId: newOrder.id,
        description: 'Pedido $orderNumber no valor de R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')} cadastrado em Orçamento.',
        timestamp: DateTime.now(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido $orderNumber criado com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar pedido: $e'), backgroundColor: AppColors.redError),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);
    final companies = companiesAsync.value ?? [];
    if (_selectedCompanyId == null && companies.isNotEmpty) {
      _selectedCompanyId = companies.first.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: Color(0xFF222421), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Novo pedido',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor Empresa
                    const Text('Empresa vinculada *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1C1D1B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF282A26))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCompanyId,
                          dropdownColor: const Color(0xFF222421),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
                          isExpanded: true,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          items: companies.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                const Icon(LucideIcons.building2, color: Colors.white, size: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Text(c.tradeName, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedCompanyId = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção Itens
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text('Itens do pedido', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        TextButton.icon(
                          onPressed: _showAddCustomItemDialog,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.orangeAction),
                          label: const Text('Item customizado', style: TextStyle(color: AppColors.orangeAction, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Catálogo rápido de sugestões
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickChip('+ Placa acrílica (R\$ 150)', () => _addItem('Placa acrílica NFC', 150.0)),
                          const SizedBox(width: 8),
                          _buildQuickChip('+ Cartão PVC (R\$ 80)', () => _addItem('Cartão PVC NFC', 80.0)),
                          const SizedBox(width: 8),
                          _buildQuickChip('+ Software / Setup (R\$ 100)', () => _addItem('Configuração de software', 100.0)),
                          const SizedBox(width: 8),
                          _buildQuickChip('+ Mensalidade (R\$ 90)', () => _addItem('Mensalidade de software', 90.0)),
                          const SizedBox(width: 8),
                          _buildQuickChip('+ Combo Software + Placa (R\$ 220)', () => _addItem('Combo Software + Plaquinha', 220.0)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Lista de Itens do Pedido
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF161715), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF282A26))),
                        child: const Center(
                          child: Text('Nenhum item adicionado. Toque nos botões acima para adicionar.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9E9E9E), fontSize: 13)),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildItemRow(index, item);
                      }),

                    const SizedBox(height: 20),

                    // Desconto e Observações
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Desconto (R\$)', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(color: const Color(0xFF1C1D1B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF282A26))),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: TextField(
                                  controller: _discountCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF22C55E), fontWeight: FontWeight.w700),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Observações / Notas', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(color: const Color(0xFF1C1D1B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF282A26))),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: TextField(
                                  controller: _notesCtrl,
                                  style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: Previsão 3 dias úteis',
                                    hintStyle: TextStyle(color: Color(0xFF555953), fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Card de Resumo (Warm Cream #ECEBDE)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.surfaceCream, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text('Subtotal dos itens', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280))),
                              ),
                              Text('R\$ ${_subtotal.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10110F))),
                            ],
                          ),
                          if (_discount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('Desconto concedido', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280))),
                                ),
                                Text('- R\$ ${_discount.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                              ],
                            ),
                          ],
                          const Divider(color: Color(0xFFDCDBCF), height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text('Total líquido', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10110F))),
                              ),
                              Text('R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF10110F))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Botão Laranja de Criação
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: _isCreating ? null : _handleCreateOrder,
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: _isCreating
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(
                            'Criar pedido • R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFECEBDE)),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, _OrderItemDraft item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) => item.title = val,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                onPressed: () {
                  setState(() => _items.removeAt(index));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Quantidade
              Container(
                decoration: BoxDecoration(color: const Color(0xFF141513), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (item.quantity > 1) {
                          setState(() => item.quantity--);
                        }
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.remove, size: 16, color: Color(0xFF9E9E9E))),
                    ),
                    Text('${item.quantity}', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                    InkWell(
                      onTap: () {
                        setState(() => item.quantity++);
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.add, size: 16, color: AppColors.orangeAction)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Valor Unitário (R$)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF141513), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Text('R\$ ', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9E9E9E), fontSize: 13)),
                      Expanded(
                        child: TextFormField(
                          initialValue: item.unitPrice.toStringAsFixed(2),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                          onChanged: (val) {
                            final p = double.tryParse(val.replaceAll(',', '.')) ?? item.unitPrice;
                            setState(() => item.unitPrice = p);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Subtotal do item
              Text(
                'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
