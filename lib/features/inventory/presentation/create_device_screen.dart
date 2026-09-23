import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/device_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela de Cadastro de Novo Dispositivo / Lote no Estoque.
class CreateDeviceScreen extends ConsumerStatefulWidget {
  const CreateDeviceScreen({super.key});

  @override
  ConsumerState<CreateDeviceScreen> createState() => _CreateDeviceScreenState();
}

class _CreateDeviceScreenState extends ConsumerState<CreateDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  String _deviceType = 'display_acrilico';
  String? _selectedCompanyId;
  String? _selectedServiceId;
  DeviceStatus _status = DeviceStatus.disponivel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(
      text: 'NFC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(deviceRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);
      final curUser = ref.read(currentUserProvider);

      final code = _codeCtrl.text.trim();
      final newDevice = DeviceItem(
        id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
        batchId: code,
        deviceType: _deviceType,
        assignedCompanyId: _selectedCompanyId,
        primaryServiceId: _selectedServiceId,
        status: _status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createDevice(newDevice);

      await actRepo.logActivity(
        ActivityEntry(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          actorUid: curUser?.uid ?? 'usr-operador',
          actorName: curUser?.displayName ?? 'Operador',
          actionType: 'create_device',
          description: 'Dispositivo $code cadastrado no estoque.',
          entityType: 'device',
          entityId: newDevice.id,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispositivo "$code" salvo no estoque com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar dispositivo: $e'),
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
    final companiesAsync = ref.watch(companiesStreamProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);

    final companies = companiesAsync.value ?? [];
    final allServices = servicesAsync.value ?? [];
    final availableServices = _selectedCompanyId != null
        ? allServices.where((s) => s.companyId == _selectedCompanyId).toList()
        : allServices;

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
                      decoration: const BoxDecoration(
                        color: Color(0xFF222421),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Novo dispositivo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Código / Lote
                      _buildFieldLabel('Código do lote ou tag *'),
                      TextFormField(
                        controller: _codeCtrl,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o código do dispositivo' : null,
                        decoration: _inputDecoration('Ex: NFC-00150'),
                      ),

                      const SizedBox(height: 14),

                      // Tipo de dispositivo
                      _buildFieldLabel('Tipo físico *'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: _boxDecoration(),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _deviceType,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                            items: const [
                              DropdownMenuItem(value: 'display_acrilico', child: Text('Placa acrílica')),
                              DropdownMenuItem(value: 'cartao_pvc', child: Text('Cartão PVC')),
                              DropdownMenuItem(value: 'sticker', child: Text('Sticker / Adesivo NFC')),
                            ],
                            onChanged: (v) => setState(() => _deviceType = v ?? 'display_acrilico'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Empresa vinculada
                      _buildFieldLabel('Empresa vinculada (opcional)'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: _boxDecoration(),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedCompanyId,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Nenhuma (Disponível no estoque)')),
                              ...companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.tradeName))),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectedCompanyId = v;
                                _selectedServiceId = null;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Serviço associado
                      _buildFieldLabel('Serviço primário (opcional)'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: _boxDecoration(),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedServiceId,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Nenhum serviço vinculado')),
                              ...availableServices.map((s) => DropdownMenuItem(value: s.id, child: Text(s.publicTitle))),
                            ],
                            onChanged: (v) => setState(() => _selectedServiceId = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Status
                      _buildFieldLabel('Status inicial'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: _boxDecoration(),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<DeviceStatus>(
                            value: _status,
                            dropdownColor: const Color(0xFF222421),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                            items: const [
                              DropdownMenuItem(value: DeviceStatus.disponivel, child: Text('Disponível')),
                              DropdownMenuItem(value: DeviceStatus.emProducao, child: Text('Em produção')),
                              DropdownMenuItem(value: DeviceStatus.instalado, child: Text('Instalado')),
                              DropdownMenuItem(value: DeviceStatus.defeito, child: Text('Defeito')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? DeviceStatus.disponivel),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Botão Salvar
                      Material(
                        color: AppColors.orangeAction,
                        borderRadius: BorderRadius.circular(26),
                        child: InkWell(
                          onTap: _isSaving ? null : _handleSave,
                          borderRadius: BorderRadius.circular(26),
                          child: Container(
                            height: 52,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text(
                                    'Salvar no estoque',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
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
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF191A18),
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF555953)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF282A26)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF282A26)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orangeAction),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: const Color(0xFF191A18),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF282A26)),
    );
  }
}
