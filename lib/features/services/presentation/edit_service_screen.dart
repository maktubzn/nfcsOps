import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S08 — Editar Serviço.
/// Permite alterar destino URL com aviso de QR estático e validação automática com health check.
class EditServiceScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const EditServiceScreen({super.key, required this.serviceId});

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _notesCtrl;

  String _serviceType = 'google_reviews';
  String? _companyId;
  bool _isSaving = false;
  bool _showSuccessBanner = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _urlCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  void _initFields(ServiceItem s) {
    if (_isLoaded) return;
    _isLoaded = true;
    _titleCtrl.text = s.publicTitle;
    _urlCtrl.text = s.destinationUrl;
    var st = s.serviceType;
    if (st == 'google_review') st = 'google_reviews';
    if (st == 'cardapio') st = 'cardapio_digital';
    _serviceType = st;
    _companyId = s.companyId;
    _notesCtrl.text = s.notes ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndTest(ServiceItem original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final srvRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);

      final newUrl = _urlCtrl.text.trim();
      final healthRes = await healthService.checkUrl(original.id, newUrl);

      final updated = original.copyWith(
        companyId: _companyId ?? original.companyId,
        publicTitle: _titleCtrl.text.trim(),
        destinationUrl: newUrl,
        serviceType: _serviceType,
        healthStatus: healthRes.status,
        notes: _notesCtrl.text.trim(),
        lastCheckedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await srvRepo.updateService(updated);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _showSuccessBanner = true;
      });

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: AppColors.redError),
      );
    }
  }

  Future<void> _handleDelete(ServiceItem service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Excluir serviço?', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: Text(
          'Tem certeza que deseja excluir "${service.publicTitle}"? Esta ação removerá o serviço e desvinculará os dispositivos associados.',
          style: const TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(serviceRepositoryProvider);
      await repo.deleteService(service.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Serviço "${service.publicTitle}" excluído com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir serviço: $e'),
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
    final servicesAsync = ref.watch(servicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final all = servicesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];
    final service = all.where((s) => s.id == widget.serviceId).firstOrNull;

    if (service == null) {
      if (servicesAsync.isLoading) {
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
          title: const Text('Serviço não encontrado', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Serviço não localizado no banco de dados.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    _initFields(service);

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
                    'Editar serviço',
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
                      // Banner de sucesso
                      if (_showSuccessBanner) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Destino atualizado. Link testado.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      _buildLabel('Empresa vinculada'),
                      _buildCompanyDropdown(companies),
                      const SizedBox(height: 14),

                      _buildLabel('Tipo de serviço'),
                      _buildTypeDropdown(),
                      const SizedBox(height: 14),

                      _buildLabel('Nome interno'),
                      _buildInput(_titleCtrl, 'Avaliação no balcão'),
                      const SizedBox(height: 14),

                      _buildLabel('Destino *'),
                      _buildInput(
                        _urlCtrl,
                        'https://example.com/avaliar',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe a URL de destino';
                          if (!v.startsWith('http://') && !v.startsWith('https://')) {
                            return 'URL deve iniciar com https:// ou http://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('Observação'),
                      _buildInput(_notesCtrl, 'Placa da recepção'),
                      const SizedBox(height: 18),

                      // Card de Advertência QR Estático (Warm Cream / Orange)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.orangeAction, width: 1.5),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.alertTriangle, color: AppColors.orangeAction, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'QR estático: alterar o destino exige nova impressão e regravação NFC.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10110F),
                                  height: 1.35,
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

            // Sticky Botão Laranja: "Salvar e testar"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: _isSaving ? null : () => _handleSaveAndTest(service),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          'Cancelar',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: _isSaving ? null : () => _handleDelete(service),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Excluir serviço',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
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
    final dropdownItems = <DropdownMenuItem<String>>[];
    for (final c in companies) {
      dropdownItems.add(
        DropdownMenuItem(
          value: c.id,
          child: Text(
            c.tradeName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (_companyId != null && !companies.any((c) => c.id == _companyId)) {
      dropdownItems.insert(
        0,
        DropdownMenuItem(
          value: _companyId,
          child: Text('Empresa vinculada (ID: $_companyId)'),
        ),
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
          value: _companyId,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
          items: dropdownItems,
          onChanged: (v) => setState(() => _companyId = v),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final standardTypes = <String, String>{
      'google_reviews': 'Google Reviews',
      'whatsapp': 'WhatsApp Comercial',
      'instagram': 'Instagram',
      'location': 'Localização / Maps',
      'cardapio_digital': 'Cardápio Digital',
      'wifi': 'Wi-Fi Convidado',
      'pix': 'Chave PIX / Checkout',
      'review_balcao': 'Avaliação de Balcão',
      'software_placa': 'Software + Plaquinha NFC',
      'personalizado': 'Personalizado / Outro',
    };

    final dropdownItems = <DropdownMenuItem<String>>[];
    for (final entry in standardTypes.entries) {
      dropdownItems.add(DropdownMenuItem(value: entry.key, child: Text(entry.value)));
    }

    if (!standardTypes.containsKey(_serviceType)) {
      dropdownItems.insert(0, DropdownMenuItem(value: _serviceType, child: Text('Tipo: $_serviceType')));
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
          value: _serviceType,
          dropdownColor: const Color(0xFF222421),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
          isExpanded: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.white),
          items: dropdownItems,
          onChanged: (v) => setState(() => _serviceType = v ?? 'google_reviews'),
        ),
      ),
    );
  }
}
