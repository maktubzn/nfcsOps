import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/device_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela A04 — Checklist Físico Operacional (NFC-00142).
/// Validação dos 8 itens obrigatórios (RB-007) antes da aprovação e liberação física de placas/cartões.
class PhysicalChecklistScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const PhysicalChecklistScreen({super.key, required this.deviceId});

  @override
  ConsumerState<PhysicalChecklistScreen> createState() => _PhysicalChecklistScreenState();
}

class _PhysicalChecklistScreenState extends ConsumerState<PhysicalChecklistScreen> {
  late List<bool> _checklist;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isInitialized = false;

  final List<String> _items = [
    'Arte correta',
    'Logo correta',
    'URL correta',
    'QR abre destino esperado',
    'NFC abre destino esperado',
    'NFC e QR no mesmo serviço',
    'Cliente correto',
    'Acabamento aprovado',
  ];

  @override
  void initState() {
    super.initState();
    _checklist = List.filled(8, false);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _checkedCount => _checklist.where((c) => c).length;
  bool get _allChecked => _checkedCount == 8;

  Future<void> _handleSaveProgress() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(deviceRepositoryProvider);
      final physicalChecklist = PhysicalChecklist(
        visualInspection: _checklist[0],
        nfcChipWriting: _checklist[1],
        nfcReadingTest: _checklist[2],
        qrPrintInspection: _checklist[3],
        qrScanVerification: _checklist[4],
        urlMatchConfirmation: _checklist[5],
        companyVerification: _checklist[6],
        finalPackaging: _checklist[7],
      );

      await repo.updateChecklist(widget.deviceId, physicalChecklist);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progresso do checklist salvo: $_checkedCount de 8 verificados.'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar progresso: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleApproveDevice() async {
    if (!_allChecked) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(deviceRepositoryProvider);
      final physicalChecklist = PhysicalChecklist(
        visualInspection: _checklist[0],
        nfcChipWriting: _checklist[1],
        nfcReadingTest: _checklist[2],
        qrPrintInspection: _checklist[3],
        qrScanVerification: _checklist[4],
        urlMatchConfirmation: _checklist[5],
        companyVerification: _checklist[6],
        finalPackaging: _checklist[7],
      );
      await repo.updateChecklist(widget.deviceId, physicalChecklist);
      await repo.updateStatus(widget.deviceId, DeviceStatus.instalado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispositivo APROVADO fisicamente e liberado para entrega!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aprovar dispositivo: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allDevices = devicesAsync.value ?? [];
    final allCompanies = companiesAsync.value ?? [];

    final device = allDevices.where((d) => d.id == widget.deviceId).firstOrNull;

    if (device != null && !_isInitialized) {
      _isInitialized = true;
      _checklist = [
        device.checklist.visualInspection,
        device.checklist.nfcChipWriting,
        device.checklist.nfcReadingTest,
        device.checklist.qrPrintInspection,
        device.checklist.qrScanVerification,
        device.checklist.urlMatchConfirmation,
        device.checklist.companyVerification,
        device.checklist.finalPackaging,
      ];
      if (device.notes != null && _notesCtrl.text.isEmpty) {
        _notesCtrl.text = device.notes!;
      }
    }

    final company = device != null ? allCompanies.where((c) => c.id == device.assignedCompanyId).firstOrNull : null;
    final displayCode = device != null ? (device.batchId.isNotEmpty ? device.batchId : device.id) : widget.deviceId;
    final companyName = company?.tradeName ?? 'NFC Ops';

    final progress = _checkedCount / 8.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                      decoration: const BoxDecoration(color: Color(0xFF222421), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checklist físico',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        '$displayCode • $companyName',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                    ],
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
                    // Card Creme de Progresso
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_checkedCount de 8 verificados',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF10110F)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gravação NFC feita externamente.',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: const Color(0xFFDCDBCF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                ),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10110F)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Lista dos 8 itens com checkboxes interativas
                    ...List.generate(8, (index) {
                      final isChecked = _checklist[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() => _checklist[index] = !_checklist[index]);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1D1B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF282A26)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isChecked ? const Color(0xFF22C55E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: isChecked ? const Color(0xFF22C55E) : const Color(0xFF555953),
                                      width: 2,
                                    ),
                                  ),
                                  child: isChecked ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _items[index],
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                                      color: isChecked ? Colors.white : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Metadados
                    const Text('Por Gustavo • Hoje 14:10', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280))),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Botões Finais
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  // Botão Laranja: "Salvar progresso"
                  Material(
                    color: AppColors.orangeAction,
                    borderRadius: BorderRadius.circular(26),
                    child: InkWell(
                      onTap: _isSaving ? null : _handleSaveProgress,
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text(
                                'Salvar progresso',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botão Aprovar Dispositivo (Desabilitado até 8 itens)
                  Material(
                    color: _allChecked ? const Color(0xFF22C55E) : const Color(0xFF1E201D),
                    borderRadius: BorderRadius.circular(26),
                    child: InkWell(
                      onTap: _allChecked && !_isSaving ? _handleApproveDevice : null,
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          'Aprovar dispositivo',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _allChecked ? Colors.black : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!_allChecked)
                    const Text(
                      'Conclua os 8 itens para aprovar',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
