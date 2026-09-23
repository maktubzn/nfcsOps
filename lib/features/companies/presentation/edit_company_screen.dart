import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/device_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/via_cep_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S06 — Editar Empresa.
/// Permite atualizar Nome, Categoria, Status, Responsável, Telefone, E-mail, CEP, Cidade, Estado (UF) e Endereço com persistência.
class EditCompanyScreen extends ConsumerStatefulWidget {
  final String companyId;

  const EditCompanyScreen({super.key, required this.companyId});

  @override
  ConsumerState<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends ConsumerState<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _cityCtrl;

  String _category = 'Oficina';
  String _status = 'ativa';
  String _selectedState = 'SP';
  bool _isSaving = false;
  bool _isSearchingCep = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cepCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
  }

  void _initFields(Company c) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameCtrl.text = c.tradeName;
    _category = c.category;
    _status = c.status;
    _contactCtrl.text = c.contactName ?? '';
    _phoneCtrl.text = c.phone ?? '';
    _emailCtrl.text = c.email ?? '';
    _addressCtrl.text = c.notes ?? '';

    // Extrair Cidade e UF reais
    if (c.city != null && c.city!.isNotEmpty) {
      if (c.city!.contains('/')) {
        final parts = c.city!.split('/');
        _cityCtrl.text = parts.first.trim();
        final parsedUf = parts.last.trim().toUpperCase();
        if (ViaCepService.brazilianStates.contains(parsedUf)) {
          _selectedState = parsedUf;
        }
      } else {
        _cityCtrl.text = c.city!;
      }
    } else if (c.notes != null && c.notes!.toLowerCase().contains('mairinque')) {
      _cityCtrl.text = 'Mairinque';
      _selectedState = 'SP';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cepCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupCep() async {
    final raw = _cepCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() => _isSearchingCep = true);
    try {
      final res = await ViaCepService.fetchCep(raw);
      if (res != null) {
        if (res.logradouro.isNotEmpty) {
          final addr = '${res.logradouro}${res.bairro.isNotEmpty ? ' - ${res.bairro}' : ''}';
          _addressCtrl.text = addr;
        }
        if (res.localidade.isNotEmpty) {
          _cityCtrl.text = res.localidade;
        }
        if (res.uf.isNotEmpty && ViaCepService.brazilianStates.contains(res.uf.toUpperCase())) {
          setState(() => _selectedState = res.uf.toUpperCase());
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Endereço localizado: ${res.localidade} / ${res.uf}'),
              backgroundColor: AppColors.greenSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado ou inválido.'),
              backgroundColor: AppColors.orangeAction,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSearchingCep = false);
    }
  }

  Future<void> _handleSave(Company original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(companyRepositoryProvider);

      String formattedCity = '';
      if (_cityCtrl.text.trim().isNotEmpty) {
        formattedCity = '${_cityCtrl.text.trim()} / $_selectedState';
      } else if (_addressCtrl.text.toLowerCase().contains('mairinque')) {
        formattedCity = 'Mairinque / SP';
      }

      final updated = original.copyWith(
        tradeName: _nameCtrl.text.trim(),
        category: _category,
        status: _status,
        contactName: _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        city: formattedCity.isNotEmpty ? formattedCity : original.city,
        notes: _addressCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await repo.updateCompany(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa atualizada com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar empresa: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete(Company company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Excluir empresa?', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir "${company.tradeName}"?',
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Os dispositivos vinculados retornarão para o estoque como "Disponível".\n• Os serviços e pedidos associados a esta empresa serão removidos.\n\nEsta ação não pode ser desfeita.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter', fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir empresa', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final compRepo = ref.read(companyRepositoryProvider);
      final devRepo = ref.read(deviceRepositoryProvider);
      final srvRepo = ref.read(serviceRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);

      // 1. Desvincular dispositivos vinculados a esta empresa (retornam a disponivel)
      final allDevs = await devRepo.getDevices(companyId: company.id);
      for (final dev in allDevs) {
        final unlinked = dev.copyWith(
          clearAssignedCompany: true,
          clearPrimaryService: true,
          status: DeviceStatus.disponivel,
          updatedAt: DateTime.now(),
        );
        await devRepo.updateDevice(unlinked);
      }

      // 2. Remover serviços vinculados
      final allServices = await srvRepo.getServicesByCompanyId(company.id);
      for (final srv in allServices) {
        await srvRepo.deleteService(srv.id);
      }

      // 3. Remover pedidos vinculados
      final allOrders = await orderRepo.getOrders(companyId: company.id);
      for (final ord in allOrders) {
        await orderRepo.deleteOrder(ord.id);
      }

      // 4. Remover a empresa
      await compRepo.deleteCompany(company.id);

      // 5. Registrar auditoria
      await actRepo.logActivity(ActivityEntry(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        actorUid: 'usr-001',
        actorName: 'Operador NFC Ops',
        actionType: 'delete',
        entityType: 'company',
        entityId: company.id,
        description: 'Exclusão da empresa "${company.tradeName}" e desvinculação de estoque',
        timestamp: DateTime.now(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Empresa "${company.tradeName}" e vínculos excluídos com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/companies');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir empresa: $e'),
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
    final all = companiesAsync.value ?? [];
    final company = all.where((c) => c.id == widget.companyId).firstOrNull;

    if (company == null) {
      if (companiesAsync.isLoading) {
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
          title: const Text('Empresa não encontrada', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Empresa não localizada no banco de dados.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    _initFields(company);

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
                    'Editar empresa',
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nome da empresa *'),
                      _buildInput(_nameCtrl),
                      const SizedBox(height: 14),

                      _buildLabel('Categoria *'),
                      _buildDropdown(
                        value: _category,
                        items: [
                          'Oficina',
                          'Cafeteria',
                          'Restaurante',
                          'Restaurante / Cafeteria',
                          'Barbearia',
                          'Pet shop',
                          'Varejo',
                          'Saúde / Clínica',
                          'Estética / Salão',
                          'Outros',
                        ],
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('Status *'),
                      _buildStatusDropdown(),
                      const SizedBox(height: 14),

                      _buildLabel('Responsável'),
                      _buildInput(_contactCtrl),
                      const SizedBox(height: 14),

                      _buildLabel('Telefone'),
                      _buildInput(_phoneCtrl, hint: '+55 11 99999-9999', keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),

                      _buildLabel('E-mail'),
                      _buildInput(_emailCtrl, hint: 'contato@empresa.com', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),

                      _buildLabel('CEP (busca automática de endereço)'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              _cepCtrl,
                              hint: '00000-000',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                                if (clean.length == 8) _lookupCep();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _isSearchingCep ? null : _lookupCep,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222421),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF2E302C)),
                              ),
                              child: _isSearchingCep
                                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orangeAction)))
                                  : const Row(
                                      children: [
                                        Icon(Icons.search, size: 18, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Buscar', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Cidade *'),
                                _buildInput(_cityCtrl, hint: 'Ex: Mairinque'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Estado (UF) *'),
                                _buildStateDropdown(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('Endereço (Rua, número, bairro)'),
                      _buildInput(_addressCtrl, hint: 'Ex: R. São Paulo, 94 - Centro'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons: Salvar alterações / Cancelar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Material(
                    color: AppColors.orangeAction,
                    borderRadius: BorderRadius.circular(26),
                    child: InkWell(
                      onTap: _isSaving ? null : () => _handleSave(company),
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Salvar alterações',
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _isSaving ? null : () => _handleDelete(company),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Excluir empresa',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ViaCepService.brazilianStates.contains(_selectedState) ? _selectedState : 'SP',
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
          items: ViaCepService.brazilianStates
              .map((uf) => DropdownMenuItem(value: uf, child: Text(uf, style: const TextStyle(color: Colors.white))))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedState = v);
          },
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveItems = List<String>.from(items);
    if (value.isNotEmpty && !effectiveItems.contains(value)) {
      effectiveItems.insert(0, value);
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveItems.contains(value) ? value : effectiveItems.first,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
          items: effectiveItems.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final statusList = ['ativa', 'lead', 'inativa'];
    final currentStatus = _status.toLowerCase();
    final effectiveStatus = statusList.contains(currentStatus) ? currentStatus : 'ativa';

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveStatus,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'ativa', child: Text('Ativa', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'lead', child: Text('Lead', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'inativa', child: Text('Inativa', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (v) => setState(() => _status = v ?? 'ativa'),
        ),
      ),
    );
  }
}
