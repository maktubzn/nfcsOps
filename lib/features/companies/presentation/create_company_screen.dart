import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/company.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/via_cep_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S04 — Cadastro de Empresa.
/// Formulário com validação real, seções colapsáveis, card de sugestões e persistência no CompanyRepository.
class CreateCompanyScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final String? initialStatus;
  final String? initialContact;
  final String? initialPhone;
  final String? initialCityUf;

  const CreateCompanyScreen({
    super.key,
    this.initialName,
    this.initialCategory,
    this.initialStatus,
    this.initialContact,
    this.initialPhone,
    this.initialCityUf,
  });

  @override
  ConsumerState<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityUfController;
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _complementController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Oficina';
  String _status = 'ativa';
  String _selectedState = 'SP';
  bool _expandOptional = false;
  bool _expandNotes = false;
  bool _isSaving = false;
  bool _isSearchingCep = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _contactController = TextEditingController(text: widget.initialContact ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _cityUfController = TextEditingController(text: widget.initialCityUf ?? '');
    if (widget.initialCategory != null) _category = widget.initialCategory!;
    if (widget.initialStatus != null) _status = widget.initialStatus!;

    if (widget.initialCityUf != null && widget.initialCityUf!.isNotEmpty) {
      if (widget.initialCityUf!.contains('/')) {
        final parts = widget.initialCityUf!.split('/');
        _cityController.text = parts.first.trim();
        final uf = parts.last.trim().toUpperCase();
        if (ViaCepService.brazilianStates.contains(uf)) _selectedState = uf;
      } else {
        _cityController.text = widget.initialCityUf!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _cityUfController.dispose();
    _cepController.dispose();
    _cityController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _complementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _lookupCep() async {
    final raw = _cepController.text.trim();
    if (raw.isEmpty) return;
    setState(() => _isSearchingCep = true);
    try {
      final res = await ViaCepService.fetchCep(raw);
      if (res != null) {
        if (res.logradouro.isNotEmpty) {
          final addr = '${res.logradouro}${res.bairro.isNotEmpty ? ' - ${res.bairro}' : ''}';
          _addressController.text = addr;
        }
        if (res.localidade.isNotEmpty) {
          _cityController.text = res.localidade;
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(companyRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);

      String formattedCity = '';
      if (_cityController.text.trim().isNotEmpty) {
        formattedCity = '${_cityController.text.trim()} / $_selectedState';
      } else if (_cityUfController.text.trim().isNotEmpty) {
        formattedCity = _cityUfController.text.trim();
      } else if (_addressController.text.toLowerCase().contains('mairinque')) {
        formattedCity = 'Mairinque / SP';
      }

      final cityParts = formattedCity.split('/');
      final city = cityParts.isNotEmpty ? cityParts.first.trim() : '';
      final state = cityParts.length > 1 ? cityParts[1].trim() : 'SP';

      final newCompany = Company(
        id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
        tradeName: _nameController.text.trim(),
        legalName: _nameController.text.trim(),
        document: _documentController.text.trim().isEmpty ? null : _documentController.text.trim(),
        category: _category,
        contactName: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        city: formattedCity.isNotEmpty ? formattedCity : null,
        status: _status,
        notes: [
          if (_addressController.text.trim().isNotEmpty) _addressController.text.trim(),
          if (_complementController.text.trim().isNotEmpty) _complementController.text.trim(),
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
        ].join(' • '),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createCompany(newCompany);

      final currentUser = ref.read(currentUserProvider);
      await actRepo.logActivity(
        ActivityEntry(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          actorUid: currentUser?.uid ?? 'usr-operador',
          actorName: currentUser?.displayName ?? 'Operador',
          actionType: 'create',
          description: '${newCompany.tradeName} (${newCompany.category}) foi criada.',
          entityType: 'company',
          entityId: newCompany.id,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Empresa "${newCompany.tradeName}" cadastrada com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar empresa: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Top Bar com seta de voltar e título centralizado (y: 24..72 px)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF222421),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Nova empresa',
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
            ),

            // 2. Formulário com rolagem contendo campos, sugestões e botão Salvar
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18), // Top bar ends at 72 + 18 = 90 px

                      // Campo 1: Nome da empresa * (y: 90..152)
                      _buildFieldLabel('Nome da empresa *'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Auto Center Silva',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Informe o nome da empresa';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 9),

                      // Campo 2: Categoria * (y: 161..228)
                      _buildFieldLabel('Categoria *'),
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
                        onChanged: (val) => setState(() => _category = val!),
                      ),

                      const SizedBox(height: 9),

                      // Campo 3: Status * (y: 237..304)
                      _buildFieldLabel('Status *'),
                      _buildStatusDropdown(),

                      const SizedBox(height: 9),

                      // Campo 4: Responsável (y: 313..380)
                      _buildFieldLabel('Responsável'),
                      _buildTextField(
                        controller: _contactController,
                        hint: 'Nome completo do contato',
                      ),

                      const SizedBox(height: 9),

                      // Campo 5: WhatsApp (y: 389..456)
                      _buildFieldLabel('WhatsApp'),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'DDD + WhatsApp (ex: 11999990142)',
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 9),

                      // Campo 6: CEP com busca automática
                      _buildFieldLabel('CEP (busca automática de endereço)'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cepController,
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
                              height: 46,
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

                      const SizedBox(height: 9),

                      // Campo 7: Cidade e Estado (UF)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Cidade *'),
                                _buildTextField(
                                  controller: _cityController,
                                  hint: 'Ex: Mairinque',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Estado (UF) *'),
                                _buildStateDropdown(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // Campo 8: Endereço completo
                      _buildFieldLabel('Endereço (Rua, número, bairro)'),
                      _buildTextField(
                        controller: _addressController,
                        hint: 'Ex: R. São Paulo, 94 - Centro',
                      ),

                      const SizedBox(height: 16),

                      // Accordion 1: Mais dados opcionais (y: 548..583)
                      _buildCollapsibleSection(
                        title: 'Mais dados opcionais',
                        isExpanded: _expandOptional,
                        onToggle: () => setState(() => _expandOptional = !_expandOptional),
                        children: [
                          const SizedBox(height: 8),
                          _buildFieldLabel('CNPJ'),
                          _buildTextField(controller: _documentController, hint: '00.000.000/0001-00'),
                          const SizedBox(height: 8),
                          _buildFieldLabel('E-mail'),
                          _buildTextField(controller: _emailController, hint: 'contato@empresa.com'),
                          const SizedBox(height: 8),
                          _buildFieldLabel('Complemento / Bairro'),
                          _buildTextField(controller: _complementController, hint: 'Ex: Sala 102, Bloco A ou Centro'),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Accordion 2: Logo e observações (y: 588..623)
                      _buildCollapsibleSection(
                        title: 'Logo e observações',
                        isExpanded: _expandNotes,
                        onToggle: () => setState(() => _expandNotes = !_expandNotes),
                        children: [
                          const SizedBox(height: 8),
                          _buildFieldLabel('Observações internas'),
                          _buildTextField(controller: _notesController, hint: 'Notas operacionais...', maxLines: 3),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Card de Sugestões: "Sugestões para oficinas" (y: 637..774)
                      _buildSuggestionsCard(),

                      const SizedBox(height: 15),

                      // Botão "Salvar empresa" (y: 789..845)
                      Semantics(
                        button: true,
                        label: 'Salvar empresa',
                        child: Material(
                          color: AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            onTap: _isSaving ? null : _handleSave,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              height: 56,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Salvar empresa',
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
                      ),

                      const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(bottom: 3),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: maxLines == 1 ? 12 : 12),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ViaCepService.brazilianStates.contains(_selectedState) ? _selectedState : 'SP',
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          items: ViaCepService.brazilianStates.map((uf) {
            return DropdownMenuItem<String>(
              value: uf,
              child: Text(uf, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
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
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveItems.contains(value) ? value : effectiveItems.first,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          items: effectiveItems.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
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
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveStatus,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'ativa',
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6ABB34),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ativa', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'lead',
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFACC15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Lead', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'inativa',
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Inativa', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
            ),
          ],
          onChanged: (val) => setState(() => _status = val ?? 'ativa'),
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLightbulbIcon(),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sugestões para oficinas',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10110F),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Recursos que podem ajudar na sua operação.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildSuggestionChip(
                icon: const Icon(Icons.settings, size: 16, color: Color(0xFF10110F)),
                label: 'Reviews',
              ),
              _buildSuggestionChip(
                icon: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.4,
                      child: const Icon(Icons.phone, color: Colors.white, size: 10),
                    ),
                  ),
                ),
                label: 'WhatsApp',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.info, size: 14, color: Color(0xFF8E8E93)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Adicione serviços após salvar.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightbulbIcon() {
    return SizedBox(
      width: 26,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(26, 28),
            painter: _LightbulbRaysPainter(),
          ),
          Positioned(
            top: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFFACC15), size: 18),
                Container(
                  width: 5,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F8387),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip({required Widget icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDBCF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0CEBF), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10110F),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightbulbRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFACC15)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2 - 2);
    const angles = [-1.0, -0.5, 0.0, 0.5, 1.0];
    for (final a in angles) {
      final dx = math.sin(a);
      final dy = -math.cos(a);
      canvas.drawLine(
        Offset(center.dx + dx * 10, center.dy + dy * 10),
        Offset(center.dx + dx * 12.5, center.dy + dy * 12.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
