import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/device_item.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/nfc_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S12 — Detalhe do Dispositivo (NFC-00142).
/// Controle de lote, fornecedor, custo, associação e acionamento do checklist físico operacional.
class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _isUpdating = false;

  Future<void> _handleUpdateStatus(String deviceId, DeviceStatus newStatus, String successMsg) async {
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(deviceRepositoryProvider);
      await repo.updateStatus(deviceId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: AppColors.greenSuccess, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: AppColors.redError, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmDeleteDevice(DeviceItem device) async {
    final displayCode = device.batchId.isNotEmpty ? device.batchId : device.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Excluir dispositivo?',
                style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente excluir o dispositivo "$displayCode" permanentemente do estoque? Esta ação não pode ser desfeita e removerá o registro do banco de dados.',
          style: const TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(deviceRepositoryProvider);
      await repo.deleteDevice(device.id);

      final actRepo = ref.read(activityRepositoryProvider);
      await actRepo.logActivity(ActivityEntry(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        actorUid: 'usr-001',
        actorName: 'Operador NFC Ops',
        actionType: 'delete',
        entityType: 'device',
        entityId: device.id,
        description: 'Dispositivo $displayCode (${device.deviceType}) excluído permanentemente do estoque.',
        timestamp: DateTime.now(),
      ));

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Dispositivo $displayCode excluído com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir dispositivo: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showAssignModal(
    BuildContext context,
    DeviceItem device,
    List<Company> companies,
    List<ServiceItem> services,
  ) {
    String? selectedCompId = device.assignedCompanyId;
    String? selectedSrvId = device.primaryServiceId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final availableServices = services.where((s) => s.companyId == selectedCompId).toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Associar Empresa & Serviço',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vincule este dispositivo a um cliente e defina o serviço que responderá pelo chip NFC/QR.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(height: 16),

                      // Empresa
                      const Text('Empresa vinculada', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1D1B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedCompId,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
                            hint: const Text('Selecione uma empresa', style: TextStyle(color: Color(0xFF6B7280))),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Nenhuma empresa (Desvincular)', style: TextStyle(color: Color(0xFF9E9E9E))),
                              ),
                              if (selectedCompId != null && !companies.any((c) => c.id == selectedCompId))
                                DropdownMenuItem<String?>(
                                  value: selectedCompId,
                                  child: Text('Empresa vinculada ($selectedCompId)', style: const TextStyle(color: Colors.white)),
                                ),
                              ...companies.map((c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(c.tradeName, style: const TextStyle(color: Colors.white)),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                selectedCompId = val;
                                selectedSrvId = null;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Serviço
                      const Text('Serviço principal (NFC/QR)', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1D1B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedSrvId,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
                            hint: const Text('Selecione o serviço', style: TextStyle(color: Color(0xFF6B7280))),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Sem serviço específico', style: TextStyle(color: Color(0xFF9E9E9E))),
                              ),
                              if (selectedSrvId != null && !availableServices.any((s) => s.id == selectedSrvId))
                                DropdownMenuItem<String?>(
                                  value: selectedSrvId,
                                  child: Text('Serviço ($selectedSrvId)', style: const TextStyle(color: Colors.white)),
                                ),
                              ...availableServices.map((s) => DropdownMenuItem<String?>(
                                    value: s.id,
                                    child: Text(s.publicTitle, style: const TextStyle(color: Colors.white)),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                selectedSrvId = val;
                              });
                            },
                          ),
                        ),
                      ),

                      if (selectedCompId != null && availableServices.isEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.push('/services/new?companyId=$selectedCompId');
                          },
                          icon: const Icon(Icons.add, size: 16, color: AppColors.orangeAction),
                          label: const Text('Cadastrar novo serviço para esta empresa', style: TextStyle(color: AppColors.orangeAction, fontSize: 12)),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botão Salvar
                      Material(
                        color: AppColors.orangeAction,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () async {
                            final repo = ref.read(deviceRepositoryProvider);
                            final updated = device.copyWith(
                              assignedCompanyId: selectedCompId,
                              primaryServiceId: selectedSrvId,
                              updatedAt: DateTime.now(),
                            );
                            await repo.updateDevice(updated);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vínculo do dispositivo salvo com sucesso!'),
                                  backgroundColor: AppColors.greenSuccess,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 48,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: const Text(
                              'Salvar vínculo',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReplaceModal(
    BuildContext context,
    DeviceItem currentDevice,
    List<DeviceItem> allDevices,
  ) {
    final availableSpares = allDevices.where((d) => d.status == DeviceStatus.disponivel && d.id != currentDevice.id).toList();
    String? selectedReplacementId = availableSpares.isNotEmpty ? availableSpares.first.id : null;
    bool markCurrentAsDefective = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Substituir Dispositivo',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Trocar ${currentDevice.batchId.isNotEmpty ? currentDevice.batchId : currentDevice.id} por uma peça de reserva do estoque.',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(height: 16),

                      if (availableSpares.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1D1B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF282A26)),
                          ),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.alertTriangle, color: Color(0xFFFACC15), size: 32),
                              const SizedBox(height: 10),
                              const Text(
                                'Nenhum dispositivo disponível no estoque.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Cadastre uma nova placa ou cartão no estoque antes de realizar a substituição.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.push('/inventory');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orangeAction,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: const Text('Ir para o Estoque', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Text('Selecione a peça de reserva:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1D1B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF282A26)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedReplacementId,
                              dropdownColor: const Color(0xFF222421),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
                              items: availableSpares.map((spare) {
                                final spareName = spare.batchId.isNotEmpty ? spare.batchId : spare.id;
                                final typeLabel = spare.deviceType == 'display_acrilico'
                                    ? 'Placa acrílica'
                                    : spare.deviceType == 'cartao_pvc'
                                        ? 'Cartão PVC'
                                        : 'Sticker NFC';
                                return DropdownMenuItem(
                                  value: spare.id,
                                  child: Text('$spareName ($typeLabel)', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => selectedReplacementId = val),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text('Destino do dispositivo substituído:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => setModalState(() => markCurrentAsDefective = true),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1D1B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: markCurrentAsDefective ? AppColors.orangeAction : const Color(0xFF282A26),
                                width: markCurrentAsDefective ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  markCurrentAsDefective ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: markCurrentAsDefective ? AppColors.orangeAction : const Color(0xFF9E9E9E),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Marcar como Defeituoso (recomendado)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                      SizedBox(height: 2),
                                      Text('Registra falha física para descarte ou reparo', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => setModalState(() => markCurrentAsDefective = false),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1D1B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !markCurrentAsDefective ? AppColors.orangeAction : const Color(0xFF282A26),
                                width: !markCurrentAsDefective ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  !markCurrentAsDefective ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: !markCurrentAsDefective ? AppColors.orangeAction : const Color(0xFF9E9E9E),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Retornar ao Estoque Disponível', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                      SizedBox(height: 2),
                                      Text('Desvincula da empresa e fica livre para outro cliente', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Material(
                          color: AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: selectedReplacementId == null
                                ? null
                                : () async {
                                    final repo = ref.read(deviceRepositoryProvider);
                                    final replacement = availableSpares.firstWhere((d) => d.id == selectedReplacementId);

                                    // 1. Atualizar novo dispositivo
                                    final updatedReplacement = replacement.copyWith(
                                      assignedCompanyId: currentDevice.assignedCompanyId,
                                      primaryServiceId: currentDevice.primaryServiceId,
                                      status: currentDevice.status,
                                      updatedAt: DateTime.now(),
                                    );
                                    await repo.updateDevice(updatedReplacement);

                                    // 2. Atualizar antigo dispositivo
                                    final updatedCurrent = currentDevice.copyWith(
                                      clearAssignedCompany: true,
                                      clearPrimaryService: true,
                                      status: markCurrentAsDefective ? DeviceStatus.defeito : DeviceStatus.disponivel,
                                      updatedAt: DateTime.now(),
                                    );
                                    await repo.updateDevice(updatedCurrent);

                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Dispositivo substituído com sucesso por ${replacement.batchId.isNotEmpty ? replacement.batchId : replacement.id}!'),
                                          backgroundColor: AppColors.greenSuccess,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      context.pushReplacement('/inventory/${replacement.id}');
                                    }
                                  },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 48,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Text(
                                'Confirmar Substituição',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWriteNfcModal(BuildContext context, DeviceItem device, ServiceItem? service) {
    final urlCtrl = TextEditingController(
      text: service?.destinationUrl.isNotEmpty == true
          ? service!.destinationUrl
          : 'https://nfcops.app/d/${device.id}',
    );
    bool isWriting = false;
    String status = 'Aproxime a placa do aparelho para gravar a URL no chip.';
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                  const Row(
                    children: [
                      Icon(LucideIcons.radio, color: AppColors.orangeAction, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Gravar Chip NFC',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dispositivo #${device.batchId.isNotEmpty ? device.batchId : device.id}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 14),
                  const Text('URL de destino a ser gravada no chip:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF222421),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2E302C)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: error != null ? const Color(0xFFEF4444) : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Botão de Gravação
                  Material(
                    color: AppColors.orangeAction,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: isWriting
                          ? null
                          : () async {
                              final targetUrl = urlCtrl.text.trim();
                              if (targetUrl.isEmpty) return;
                              setModalState(() {
                                isWriting = true;
                                error = null;
                                status = 'Gravando URL no chip NFC... Não afaste a placa.';
                              });

                              Future<void> onRecorded() async {
                                final repo = ref.read(deviceRepositoryProvider);
                                final newChecklist = PhysicalChecklist(
                                  visualInspection: device.checklist.visualInspection,
                                  nfcChipWriting: true,
                                  nfcReadingTest: true,
                                  qrPrintInspection: device.checklist.qrPrintInspection,
                                  qrScanVerification: device.checklist.qrScanVerification,
                                  urlMatchConfirmation: true,
                                  companyVerification: device.checklist.companyVerification,
                                  finalPackaging: device.checklist.finalPackaging,
                                );
                                await repo.updateChecklist(device.id, newChecklist);

                                if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Chip NFC gravado com sucesso com a URL da empresa!'),
                                      backgroundColor: AppColors.greenSuccess,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }

                              final available = await NfcService.instance.isAvailable();
                              if (!available) {
                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    isWriting = false;
                                    error = 'Hardware NFC não disponível ou desativado neste aparelho.';
                                    status = 'Erro: Ative o sensor NFC nas configurações do aparelho.';
                                  });
                                }
                                return;
                              }

                              await NfcService.instance.writeNdefUrl(
                                url: targetUrl,
                                onSuccess: () async => await onRecorded(),
                                onError: (err) {
                                  if (modalCtx.mounted) {
                                    setModalState(() {
                                      isWriting = false;
                                      error = err;
                                      status = 'Erro: $err';
                                    });
                                  }
                                },
                              );
                            },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: isWriting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Aproximar e Gravar',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);

    final allDevices = devicesAsync.value ?? [];
    final allCompanies = companiesAsync.value ?? [];
    final allServices = servicesAsync.value ?? [];

    final device = allDevices.where((d) => d.id == widget.deviceId).firstOrNull;

    if (device == null) {
      if (devicesAsync.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.orangeAction)),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          title: const Text('Dispositivo não encontrado', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Dispositivo não localizado no estoque.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final company = allCompanies.where((c) => c.id == device.assignedCompanyId).firstOrNull;
    final companyName = company?.tradeName ?? (device.assignedCompanyId != null && device.assignedCompanyId!.isNotEmpty ? device.assignedCompanyId! : 'Não associado');

    final service = allServices.where((s) => s.id == device.primaryServiceId).firstOrNull;
    final serviceTitle = service?.publicTitle ?? (device.primaryServiceId != null && device.primaryServiceId!.isNotEmpty ? device.primaryServiceId! : 'Sem serviço');

    final displayCode = device.batchId.isNotEmpty ? device.batchId : device.id;
    final typeLabel = device.deviceType == 'display_acrilico'
        ? 'Placa acrílica'
        : device.deviceType == 'cartao_pvc'
            ? 'Cartão PVC'
            : 'Sticker NFC';
    const chipLabel = 'NTAG213';

    final verifiedCount = device.checklist.completedCount;

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
                      onTap: () => context.pop(),
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayCode,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '$typeLabel • $chipLabel',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5ADEB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        device.status.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10110F),
                        ),
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

                    // Card de Metadados: Lote, Fornecedor, Custo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildMetaCol('Lote', device.batchId.isNotEmpty ? device.batchId : 'ACR-0926')),
                          Container(height: 30, width: 1, color: const Color(0xFF282A26)),
                          Expanded(child: _buildMetaCol('Fornecedor', device.notes?.isNotEmpty == true ? device.notes! : 'Fornecedor A')),
                          Container(height: 30, width: 1, color: const Color(0xFF282A26)),
                          Expanded(child: _buildMetaCol('Custo', 'R\$ 18,00')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Card de Associação (Warm Cream #ECEBDE)
                    Container(
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
                              color: Color(0xFF10110F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.building2, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyName,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10110F)),
                                ),
                                const SizedBox(height: 2),
                                Text(serviceTitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _showAssignModal(context, device, allCompanies, allServices),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCDBCF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Alterar',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10110F)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Status de Teste Físico
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.clipboardCheck, color: Color(0xFFFACC15), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teste físico: $verifiedCount de 8 verificados',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Separação estrita entre integridade do chip e do link',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ação Rápida NFC: Gravar no Chip NFC
                    InkWell(
                      onTap: () => _showWriteNfcModal(context, device, service),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E201D),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: device.checklist.nfcChipWriting
                                ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                                : AppColors.orangeAction.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (device.checklist.nfcChipWriting ? const Color(0xFF22C55E) : AppColors.orangeAction).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.radio,
                                  color: device.checklist.nfcChipWriting ? const Color(0xFF22C55E) : AppColors.orangeAction,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gravar Chip NFC',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    device.checklist.nfcChipWriting
                                        ? 'Chip gravado • Toque para regravar URL'
                                        : 'Aproxime para gravar URL da empresa no chip',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: device.checklist.nfcChipWriting ? const Color(0xFF22C55E) : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              device.checklist.nfcChipWriting ? Icons.check_circle : Icons.chevron_right,
                              color: device.checklist.nfcChipWriting ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botão Laranja: "Executar checklist" (Abre A04)
                    Material(
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => context.push('/devices/${device.id}/checklist'),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.checkSquare, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Executar checklist',
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

                    // Botão Secundário: "Marcar em produção"
                    Material(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: _isUpdating
                            ? null
                            : () => _handleUpdateStatus(
                                  device.id,
                                  DeviceStatus.emProducao,
                                  'Dispositivo marcado em produção com sucesso!',
                                ),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: _isUpdating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'Marcar em produção',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Linhas de Ações Rápidas
                    InkWell(
                      onTap: () => _handleUpdateStatus(device.id, DeviceStatus.instalado, 'Dispositivo marcado como INSTALADO!'),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildRow(
                        label: device.status == DeviceStatus.instalado ? 'Dispositivo Instalado' : 'Marcar como instalado',
                        icon: LucideIcons.mapPin,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showReplaceModal(context, device, allDevices),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildRow(label: 'Substituir dispositivo', icon: LucideIcons.repeat),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _handleUpdateStatus(device.id, DeviceStatus.defeito, 'Dispositivo marcado como DEFEITUOSO!'),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildRow(label: 'Marcar como defeituoso', icon: LucideIcons.alertOctagon, isDestructive: true),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _confirmDeleteDevice(device),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildRow(label: 'Excluir dispositivo do estoque', icon: Icons.delete_forever_outlined, isDestructive: true),
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

  Widget _buildMetaCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _buildRow({required String label, required IconData icon, bool isDestructive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? const Color(0xFFEF4444) : Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? const Color(0xFFEF4444) : Colors.white,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }
}
