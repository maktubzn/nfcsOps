import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela A02 — Cadastro de Novo Serviço com Validação de Link e Geração de QR.
class CreateServiceScreen extends ConsumerStatefulWidget {
  final String? initialCompanyId;
  const CreateServiceScreen({super.key, this.initialCompanyId});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  String? _companyId;
  String _serviceType = 'google_reviews';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _companyId = widget.initialCompanyId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null || _companyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma empresa vinculada!')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final srvRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);

      final url = _urlCtrl.text.trim();
      final healthRes = await healthService.checkUrl('temp', url);

      final newService = ServiceItem(
        id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
        companyId: _companyId!,
        serviceType: _serviceType,
        publicTitle: _nameCtrl.text.trim(),
        internalName: _nameCtrl.text.trim(),
        destinationUrl: url,
        healthStatus: healthRes.status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastCheckedAt: DateTime.now(),
      );

      await srvRepo.createService(newService);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Serviço "${newService.publicTitle}" salvo e link validado com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Redireciona diretamente para o QR gerado
      context.pushReplacement('/qr/${newService.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar serviço: $e'), backgroundColor: AppColors.redError),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);
    final companies = companiesAsync.value ?? [];

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
                      decoration: const BoxDecoration(
                        color: Color(0xFF222421),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Novo serviço',
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
                      // Indicador de etapas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E201D),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dados → Teste → QR',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Empresa vinculada *'),
                      _buildCompanyDropdown(companies),
                      const SizedBox(height: 14),

                      _buildLabel('Tipo de serviço *'),
                      _buildTypeChips(),
                      const SizedBox(height: 14),

                      _buildLabel('Nome interno'),
                      _buildInput(_nameCtrl, 'Avaliação no balcão'),
                      const SizedBox(height: 14),

                      _buildLabel('Destino *'),
                      _buildInput(
                        _urlCtrl,
                        'https://example.com/avaliar',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe a URL do serviço';
                          if (!v.startsWith('http://') && !v.startsWith('https://')) {
                            return 'URL deve iniciar com https:// ou http://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Card Creme de Informação
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF10110F), size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Vamos testar o link antes de gerar o QR.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10110F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Botão Sticky Laranja: "Salvar e testar"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: _isSaving ? null : _handleSaveAndTest,
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
                            'Salvar e testar',
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

  Widget _buildInput(TextEditingController ctrl, String hint, {String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555953)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown(List<Company> companies) {
    if (companies.isEmpty) {
      return Container(
        height: 50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: const Text('Nenhuma empresa cadastrada', style: TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter', fontSize: 14)),
      );
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
          value: _companyId ?? (companies.isNotEmpty ? companies.first.id : null),
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
          items: companies.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.tradeName),
          )).toList(),
          onChanged: (v) => setState(() => _companyId = v),
        ),
      ),
    );
  }

  Widget _buildTypeChips() {
    final types = [
      {'key': 'google_reviews', 'label': 'Google Reviews'},
      {'key': 'whatsapp', 'label': 'WhatsApp Comercial'},
      {'key': 'instagram', 'label': 'Instagram'},
      {'key': 'location', 'label': 'Localização'},
      {'key': 'cardapio_digital', 'label': 'Cardápio Digital'},
      {'key': 'wifi', 'label': 'Wi-Fi Convidado'},
      {'key': 'pix', 'label': 'Chave PIX'},
      {'key': 'review_balcao', 'label': 'Avaliação de Balcão'},
      {'key': 'software_placa', 'label': 'Software + Plaquinha'},
      {'key': 'personalizado', 'label': 'Personalizado / Outro'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final isSelected = _serviceType == t['key'];
        return InkWell(
          onTap: () => setState(() => _serviceType = t['key']!),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orangeAction : const Color(0xFF1C1D1B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.orangeAction : const Color(0xFF282A26)),
            ),
            child: Text(
              t['label']!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
