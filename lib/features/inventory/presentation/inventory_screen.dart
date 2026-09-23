import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/device_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';
import 'widgets/nfc_scan_modal.dart';

/// Tela S11 — Estoque de Dispositivos NFC e QR.
/// Controle de chips NTAG213/215, placas acrílicas, cartões, status de reserva e alerta de reposição.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'todos'; // 'todos', 'placas', 'cartoes'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final allDevices = devicesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];

    final inStockCount = allDevices.where((d) => d.status == DeviceStatus.disponivel).length;
    final reservedCount = allDevices.where((d) => d.assignedCompanyId != null && d.status == DeviceStatus.disponivel).length;
    final inProductionCount = allDevices.where((d) => d.status == DeviceStatus.emProducao).length;
    final installedCount = allDevices.where((d) => d.status == DeviceStatus.instalado).length;
    final defectiveCount = allDevices.where((d) => d.status == DeviceStatus.defeito).length;
    final lowStockStickers = allDevices.where((d) {
      final t = d.deviceType.toLowerCase();
      return (t.contains('adesivo') || t.contains('sticker') || t.contains('tag')) && d.status == DeviceStatus.disponivel;
    }).length;

    final filteredDevices = allDevices.where((d) {
      if (_selectedFilter == 'placas') {
        final t = d.deviceType.toLowerCase();
        if (!t.contains('placa') && !t.contains('acrilico') && !t.contains('display')) {
          return false;
        }
      } else if (_selectedFilter == 'cartoes') {
        final t = d.deviceType.toLowerCase();
        if (!t.contains('cartao') && !t.contains('pvc')) {
          return false;
        }
      }

      final query = _searchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final code = d.batchId.toLowerCase();
        final id = d.id.toLowerCase();
        final type = d.deviceType.toLowerCase();
        final comp = companies.where((c) => c.id == d.assignedCompanyId).firstOrNull;
        final compName = comp?.tradeName.toLowerCase() ?? '';
        final notes = (d.notes ?? '').toLowerCase();
        if (!code.contains(query) &&
            !id.contains(query) &&
            !type.contains(query) &&
            !compName.contains(query) &&
            !notes.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              NfcAppHeader(
                showWordmark: true,
                onNotificationTap: () => context.push('/activities'),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // Título e subtítulo
                    const Text(
                      'Estoque',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gerencie seus dispositivos NFC e QR.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Dois cards lado a lado: Lilás (Em estoque) | Creme (Reservados)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 130,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA5ADEB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(LucideIcons.box, color: Color(0xFF10110F), size: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$inStockCount',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10110F),
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const Text(
                                      'em estoque',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF10110F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 130,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCream,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(LucideIcons.bookmark, color: Color(0xFF10110F), size: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$reservedCount',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10110F),
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const Text(
                                      'reservados',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF10110F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Faixa Creme de Sub-Status dinâmica
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
                                const SizedBox(width: 6),
                                Flexible(child: Text('$inProductionCount em produção', overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10110F)))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFFFACC15), size: 8),
                                const SizedBox(width: 6),
                                Flexible(child: Text('$installedCount instalados', overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10110F)))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFFEF4444), size: 8),
                                const SizedBox(width: 6),
                                Flexible(child: Text('$defectiveCount defeituosos', overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10110F)))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Barra de Busca
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Color(0xFF8E918F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Código, empresa ou lote',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            InkWell(
                              onTap: () => setState(() => _searchCtrl.clear()),
                              child: const Icon(Icons.close, size: 18, color: Color(0xFF9E9E9E)),
                            ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _openNfcScanner(context, companies),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.orangeAction.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.radio, size: 17, color: AppColors.orangeAction),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filtros: Todos, Placas, Cartões
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPill(label: 'Todos', isSelected: _selectedFilter == 'todos', onTap: () => setState(() => _selectedFilter = 'todos')),
                          const SizedBox(width: 8),
                          _buildPill(label: 'Placas', isSelected: _selectedFilter == 'placas', onTap: () => setState(() => _selectedFilter = 'placas')),
                          const SizedBox(width: 8),
                          _buildPill(label: 'Cartões', isSelected: _selectedFilter == 'cartoes', onTap: () => setState(() => _selectedFilter = 'cartoes')),
                        ],
                      ),
                    ),

                    // Alerta Laranja: "Estoque baixo • Adesivos: N" (apenas se houver itens e estoque baixo)
                    if (allDevices.isNotEmpty && lowStockStickers > 0 && lowStockStickers <= 3) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => setState(() => _selectedFilter = 'adesivos'),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.orangeAction,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Estoque baixo • Adesivos: $lowStockStickers',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Linhas dinâmicas de Dispositivos
                    if (filteredDevices.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161715),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Center(
                          child: Text(
                            allDevices.isEmpty
                                ? 'Nenhum dispositivo cadastrado no inventário.\nToque no botão abaixo para adicionar.'
                                : 'Nenhum dispositivo encontrado para o filtro selecionado.',
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
                    else
                      ...filteredDevices.map((device) {
                        final comp = companies.where((c) => c.id == device.assignedCompanyId).firstOrNull;
                        final compName = comp?.tradeName;
                        final isStock = device.status == DeviceStatus.disponivel;
                        final statusColor = isStock
                            ? const Color(0xFF22C55E)
                            : device.status == DeviceStatus.defeito
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFEA580C);

                        final statusLabel = compName != null
                            ? '${device.status.name.toUpperCase()} • $compName'
                            : device.status.name.toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildDeviceRow(
                            code: device.batchId.isNotEmpty ? device.batchId : device.id,
                            type: device.deviceType,
                            status: statusLabel,
                            statusColor: statusColor,
                            onTap: () => context.push('/inventory/${device.id}'),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Botão Escanear Placa NFC
                    Material(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => _openNfcScanner(context, companies),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.orangeAction.withValues(alpha: 0.5), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.radio, color: AppColors.orangeAction, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Escanear Placa NFC',
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

                    const SizedBox(height: 10),

                    // Botão Laranja: "+ Novo dispositivo"
                    Material(
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => _showCreateDeviceModal(context, companies),
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
                                'Novo dispositivo',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({required String label, required bool isSelected, required VoidCallback onTap}) {
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

  Widget _buildDeviceRow({
    required String code,
    required String type,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
              child: const Icon(LucideIcons.smartphone, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(type, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 7),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  void _openNfcScanner(BuildContext context, List<Company> companies) {
    NfcScanModal.show(
      context,
      companies: companies,
      onNewTagDetected: (uid, ndefUrl) {
        _showCreateDeviceModal(context, companies, initialNfcUid: uid);
      },
    );
  }

  void _showCreateDeviceModal(BuildContext context, List<Company> companies, {String? initialNfcUid}) {
    final codeCtrl = TextEditingController(
      text: initialNfcUid != null && initialNfcUid.isNotEmpty
          ? initialNfcUid
          : 'NFC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    String selectedType = 'display_acrilico';
    String? selectedCompanyId;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333532),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Novo Dispositivo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cadastre um chip, placa ou cartão no estoque.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 16),
              const Text('Código / Lote', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 6),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF222421),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Tipo de Dispositivo', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF222421),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF222421),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    items: const [
                      DropdownMenuItem(value: 'display_acrilico', child: Text('Placa acrílica')),
                      DropdownMenuItem(value: 'cartao_pvc', child: Text('Cartão PVC')),
                      DropdownMenuItem(value: 'sticker', child: Text('Sticker NFC')),
                    ],
                    onChanged: (v) => setModalState(() => selectedType = v ?? 'display_acrilico'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Empresa vinculada (opcional)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF222421),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedCompanyId,
                    dropdownColor: const Color(0xFF222421),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nenhuma (Disponível)')),
                      ...companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.tradeName))),
                    ],
                    onChanged: (v) => setModalState(() => selectedCompanyId = v),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: isSaving
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim();
                          if (code.isEmpty) return;
                          setModalState(() => isSaving = true);
                          try {
                            final repo = ref.read(deviceRepositoryProvider);
                            final actRepo = ref.read(activityRepositoryProvider);
                            final curUser = ref.read(currentUserProvider);

                            final newDevice = DeviceItem(
                              id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
                              batchId: code,
                              nfcUid: initialNfcUid ?? code,
                              deviceType: selectedType,
                              assignedCompanyId: selectedCompanyId,
                              status: DeviceStatus.disponivel,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await repo.createDevice(newDevice);

                            await actRepo.logActivity(ActivityEntry(
                              id: 'act-${DateTime.now().millisecondsSinceEpoch}',
                              actorUid: curUser?.uid ?? 'usr-operador',
                              actorName: curUser?.displayName ?? 'Operador',
                              actionType: 'create_device',
                              description: 'Dispositivo $code adicionado ao estoque.',
                              entityType: 'device',
                              entityId: newDevice.id,
                              timestamp: DateTime.now(),
                            ));

                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dispositivo $code cadastrado no estoque com sucesso!'),
                                backgroundColor: AppColors.greenSuccess,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setModalState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao criar dispositivo: $e'), backgroundColor: AppColors.redError),
                            );
                          }
                        },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Salvar dispositivo', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),),
      ),
    );
  }
}
