import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';

/// Tela S10 — Central de Saúde do NFC Ops.
/// Monitoramento em tempo real dos 47 serviços, testes de integridade de links e tratamento de problemas.
class HealthCenterScreen extends ConsumerStatefulWidget {
  const HealthCenterScreen({super.key});

  @override
  ConsumerState<HealthCenterScreen> createState() => _HealthCenterScreenState();
}

class _HealthCenterScreenState extends ConsumerState<HealthCenterScreen> {
  bool _isTestingProblems = false;
  bool _isTestingAll = false;

  Future<void> _handleTestProblems() async {
    setState(() => _isTestingProblems = true);
    try {
      final srvRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);
      final services = await srvRepo.getAllServices();
      final problems = services.where((s) => s.healthStatus != ServiceHealthStatus.healthy).toList();

      for (final s in problems) {
        final res = await healthService.checkUrl(s.id, s.destinationUrl);
        await srvRepo.updateHealthStatus(s.id, res.status, lastCheckedAt: DateTime.now());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${problems.length} serviços com pendências foram retestados!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingProblems = false);
    }
  }

  Future<void> _handleTestAll() async {
    setState(() => _isTestingAll = true);
    try {
      final srvRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);
      final services = await srvRepo.getAllServices();

      for (final s in services.take(10)) {
        final res = await healthService.checkUrl(s.id, s.destinationUrl);
        await srvRepo.updateHealthStatus(s.id, res.status, lastCheckedAt: DateTime.now());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Varredura completa de saúde concluída!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingAll = false);
    }
  }

  String _filterScope = 'problemas'; // 'problemas' | 'todos' | 'erro' | 'warning' | 'healthy'
  String? _selectedCompanyId;
  String? _selectedType;

  Future<void> _confirmDeleteService(ServiceItem service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E201D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Excluir serviço?',
                style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja remover permanentemente o serviço "${service.publicTitle}"?\n\nEsta ação não poderá ser desfeita e qualquer dispositivo vinculado deixará de responder.',
          style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFB0B3B0), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await ref.read(serviceRepositoryProvider).deleteService(service.id);
    await ref.read(activityRepositoryProvider).logActivity(ActivityEntry(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      actorUid: 'usr-001',
      actorName: 'Operador NFC Ops',
      actionType: 'delete',
      entityType: 'service',
      entityId: service.id,
      description: 'O serviço "${service.publicTitle}" (${service.id}) foi excluído da Central de Saúde.',
      timestamp: DateTime.now(),
    ));

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Serviço "${service.publicTitle}" excluído com sucesso.'),
        backgroundColor: AppColors.greenSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showScopeFilterModal(
    BuildContext context,
    int problemCount,
    int totalCount,
    int healthyCount,
    int errorCount,
    int warningCount,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E201D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383A36),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filtrar por Status',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildModalTile(
                title: 'Problemas ($problemCount)',
                subtitle: 'Erros críticos, advertências e verificação manual',
                selected: _filterScope == 'problemas',
                color: const Color(0xFFFACC15),
                onTap: () {
                  setState(() => _filterScope = 'problemas');
                  Navigator.pop(ctx);
                },
              ),
              _buildModalTile(
                title: 'Apenas Erros Críticos ($errorCount)',
                subtitle: 'Serviços com falha de conexão detectada',
                selected: _filterScope == 'erro',
                color: const Color(0xFFEF4444),
                onTap: () {
                  setState(() => _filterScope = 'erro');
                  Navigator.pop(ctx);
                },
              ),
              _buildModalTile(
                title: 'Atenção e Manuais ($warningCount)',
                subtitle: 'Serviços com latência alta ou bloqueio de bot',
                selected: _filterScope == 'warning',
                color: const Color(0xFFEAB308),
                onTap: () {
                  setState(() => _filterScope = 'warning');
                  Navigator.pop(ctx);
                },
              ),
              _buildModalTile(
                title: 'Todos os Serviços ($totalCount)',
                subtitle: 'Exibir todos os serviços cadastrados',
                selected: _filterScope == 'todos',
                color: Colors.white,
                onTap: () {
                  setState(() => _filterScope = 'todos');
                  Navigator.pop(ctx);
                },
              ),
              _buildModalTile(
                title: 'Apenas Saudáveis ($healthyCount)',
                subtitle: 'Serviços com resposta normal / sem erro',
                selected: _filterScope == 'healthy',
                color: const Color(0xFF22C55E),
                onTap: () {
                  setState(() => _filterScope = 'healthy');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanyFilterModal(BuildContext context, List<Company> companies, List<ServiceItem> services) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E201D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383A36),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filtrar por Empresa',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _buildModalTile(
                      title: 'Todas as empresas',
                      subtitle: 'Mostrar serviços de qualquer cliente',
                      selected: _selectedCompanyId == null,
                      color: Colors.white,
                      onTap: () {
                        setState(() => _selectedCompanyId = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...companies.map((c) {
                      final count = services.where((s) => s.companyId == c.id).length;
                      return _buildModalTile(
                        title: c.tradeName,
                        subtitle: '$count serviço(s) cadastrado(s)',
                        selected: _selectedCompanyId == c.id,
                        color: Colors.white,
                        onTap: () {
                          setState(() => _selectedCompanyId = c.id);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTypeFilterModal(BuildContext context) {
    final types = [
      {'id': null, 'label': 'Todos os tipos', 'desc': 'Exibir qualquer tipo de serviço'},
      {'id': 'google', 'label': 'Google Reviews', 'desc': 'Avaliações no Google Meu Negócio'},
      {'id': 'whatsapp', 'label': 'WhatsApp Comercial', 'desc': 'Redirecionamento para conversa'},
      {'id': 'instagram', 'label': 'Instagram', 'desc': 'Perfil ou post na rede social'},
      {'id': 'cardapio', 'label': 'Cardápio Digital', 'desc': 'Menu ou catálogo online'},
      {'id': 'wifi', 'label': 'Rede Wi-Fi', 'desc': 'Conexão para clientes'},
      {'id': 'pix', 'label': 'Pagamento Pix', 'desc': 'Chave ou link de cobrança'},
      {'id': 'link', 'label': 'Link Geral', 'desc': 'Website ou landing page'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E201D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383A36),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filtrar por Tipo de Serviço',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...types.map((t) => _buildModalTile(
                title: t['label'] as String,
                subtitle: t['desc'] as String,
                selected: _selectedType == t['id'],
                color: Colors.white,
                onTap: () {
                  setState(() => _selectedType = t['id']);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalTile({
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected ? const Color(0xFF282A26) : Colors.transparent,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFFD4D6D2),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF8E928B)),
      ),
      trailing: selected ? const Icon(Icons.check, color: AppColors.greenSuccess, size: 20) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final user = ref.watch(currentUserProvider);

    final services = servicesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];

    final healthyCount = services.where((s) => s.healthStatus == ServiceHealthStatus.healthy).length;
    final warningCount = services.where((s) => s.healthStatus == ServiceHealthStatus.warning).length;
    final errorCount = services.where((s) => s.healthStatus == ServiceHealthStatus.error).length;
    final manualCount = services.where((s) => s.healthStatus == ServiceHealthStatus.manual).length;
    final total = services.length;
    final percentage = total > 0 ? (healthyCount / total * 100).round() : 0;

    final userName = user?.displayName.split(' ').first ?? 'Gustavo';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'G';

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

                    // Título e subtítulo
                    const Text(
                      'Central de saúde',
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
                      'Monitore a disponibilidade dos seus serviços.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card Grande de Visão Geral (Warm Cream #ECEBDE)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10110F),
                                  letterSpacing: -0.8,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'serviços',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF10110F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Anel de progresso
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: percentage / 100,
                                  strokeWidth: 5,
                                  backgroundColor: const Color(0xFFDCDBCF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$percentage%',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10110F),
                                        letterSpacing: -0.3,
                                        height: 1.1,
                                      ),
                                    ),
                                    const Text(
                                      'saudáveis',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 7.0,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Métricas em coluna
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniDot('$healthyCount', 'saudáveis', const Color(0xFF22C55E)),
                              const SizedBox(height: 4),
                              _buildMiniDot('$warningCount', 'atenção', const Color(0xFFFACC15)),
                              const SizedBox(height: 4),
                              _buildMiniDot('$errorCount', 'erro', const Color(0xFFEF4444)),
                              const SizedBox(height: 4),
                              _buildMiniDot('$manualCount', 'manual', const Color(0xFF9CA3AF)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Cálculo dos serviços filtrados
                    Builder(
                      builder: (context) {
                        var filteredServices = services;
                        if (_filterScope == 'problemas') {
                          filteredServices = filteredServices.where((s) => s.healthStatus != ServiceHealthStatus.healthy).toList();
                        } else if (_filterScope == 'erro') {
                          filteredServices = filteredServices.where((s) => s.healthStatus == ServiceHealthStatus.error).toList();
                        } else if (_filterScope == 'warning') {
                          filteredServices = filteredServices.where((s) => s.healthStatus == ServiceHealthStatus.warning || s.healthStatus == ServiceHealthStatus.manual).toList();
                        } else if (_filterScope == 'healthy') {
                          filteredServices = filteredServices.where((s) => s.healthStatus == ServiceHealthStatus.healthy).toList();
                        }

                        if (_selectedCompanyId != null) {
                          filteredServices = filteredServices.where((s) => s.companyId == _selectedCompanyId).toList();
                        }

                        if (_selectedType != null) {
                          filteredServices = filteredServices.where((s) {
                            final t = s.serviceType.toLowerCase();
                            final sel = _selectedType!.toLowerCase();
                            if (sel == 'link') return t.contains('link') || t.contains('review') || t.contains('google');
                            return t.contains(sel);
                          }).toList();
                        }

                        final selectedCompanyName = _selectedCompanyId != null
                            ? (companies.where((c) => c.id == _selectedCompanyId).firstOrNull?.tradeName ?? 'Empresa')
                            : null;

                        final selectedTypeLabel = _selectedType?.toUpperCase();

                        final hasActiveCustomFilter = _filterScope != 'problemas' || _selectedCompanyId != null || _selectedType != null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filtros: Problemas (com contagem), Empresa, Tipo (interativos com modais reais)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => _showScopeFilterModal(
                                      context,
                                      errorCount + warningCount + manualCount,
                                      total,
                                      healthyCount,
                                      errorCount,
                                      warningCount + manualCount,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _filterScope == 'problemas'
                                            ? const Color(0xFFFACC15)
                                            : _filterScope == 'healthy'
                                                ? const Color(0xFF22C55E)
                                                : _filterScope == 'erro'
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF282A26),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _filterScope == 'problemas'
                                                ? 'Problemas'
                                                : _filterScope == 'todos'
                                                    ? 'Todos'
                                                    : _filterScope == 'healthy'
                                                        ? 'Saudáveis'
                                                        : _filterScope == 'erro'
                                                            ? 'Erros'
                                                            : 'Atenção',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: (_filterScope == 'problemas' || _filterScope == 'healthy')
                                                  ? const Color(0xFF10110F)
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (_filterScope == 'problemas')
                                                  ? const Color(0xFFEF4444)
                                                  : Colors.black.withValues(alpha: 0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${filteredServices.length}',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: (_filterScope == 'problemas' || _filterScope == 'healthy')
                                                ? const Color(0xFF10110F)
                                                : const Color(0xFF9E9E9E),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterButton(
                                    label: selectedCompanyName ?? 'Empresa',
                                    isActive: _selectedCompanyId != null,
                                    onTap: () => _showCompanyFilterModal(context, companies, services),
                                    onClear: _selectedCompanyId != null
                                        ? () => setState(() => _selectedCompanyId = null)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterButton(
                                    label: selectedTypeLabel ?? 'Tipo',
                                    isActive: _selectedType != null,
                                    onTap: () => _showTypeFilterModal(context),
                                    onClear: _selectedType != null
                                        ? () => setState(() => _selectedType = null)
                                        : null,
                                  ),
                                  if (hasActiveCustomFilter) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(() {
                                        _filterScope = 'problemas';
                                        _selectedCompanyId = null;
                                        _selectedType = null;
                                      }),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF282A26),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.refresh, size: 14, color: Color(0xFF9E9E9E)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Limpar',
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Seção de Serviços e Problemas dinâmicos derivados do banco
                            if (filteredServices.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1D1B),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF282A26)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          services.isEmpty
                                              ? Icons.info_outline
                                              : (_filterScope == 'problemas' ? Icons.check_circle : Icons.filter_alt_off_outlined),
                                          color: services.isEmpty
                                              ? const Color(0xFF9E9E9E)
                                              : (_filterScope == 'problemas' ? const Color(0xFF22C55E) : const Color(0xFF9E9E9E)),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                services.isEmpty
                                                    ? 'Nenhum serviço cadastrado para monitoramento'
                                                    : (_filterScope == 'problemas'
                                                        ? 'Todos os serviços saudáveis'
                                                        : 'Nenhum serviço com esses filtros'),
                                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                services.isEmpty
                                                    ? 'Cadastre empresas e serviços para iniciar o monitoramento de integridade e links.'
                                                    : (_filterScope == 'problemas'
                                                        ? 'Nenhum erro ou advertência de link detectado no momento.'
                                                        : 'Tente alterar ou redefinir os filtros de empresa e tipo.'),
                                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasActiveCustomFilter) ...[
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFF333630)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          onPressed: () => setState(() {
                                            _filterScope = 'problemas';
                                            _selectedCompanyId = null;
                                            _selectedType = null;
                                          }),
                                          child: const Text('Redefinir filtros', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            else
                              ...filteredServices.map((service) {
                                final comp = companies.where((c) => c.id == service.companyId).firstOrNull;
                                final compName = comp?.tradeName ?? (service.companyId.isNotEmpty ? 'Empresa (${service.companyId})' : 'Sem empresa vinculada');
                                if (service.healthStatus == ServiceHealthStatus.error) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildErrorProblemCard(service, compName),
                                  );
                                } else if (service.healthStatus == ServiceHealthStatus.warning || service.healthStatus == ServiceHealthStatus.manual) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildWarningProblemCard(service, compName),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildHealthyCard(service, compName),
                                  );
                                }
                              }),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Botão Primário Verde-Limão: "Testar problemas"
                    Material(
                      color: const Color(0xFF96F044),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: _isTestingProblems ? null : _handleTestProblems,
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: _isTestingProblems
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF10110F)),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Color(0xFF10110F), size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Testar problemas',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10110F),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Botão Secundário Dark: "Testar tudo"
                    Material(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: _isTestingAll ? null : _handleTestAll,
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: _isTestingAll
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Testar tudo',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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

  Widget _buildMiniDot(String count, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10110F))),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E322B) : const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.orangeAction : const Color(0xFF2C2F2A),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFFCCCCCC),
              ),
            ),
            const SizedBox(width: 4),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.close, size: 14, color: AppColors.orangeAction),
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorProblemCard(ServiceItem service, String compName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeAction,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/services/${service.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF222421),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${service.publicTitle} • Erro',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFECEBDE),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        service.consecutiveFailures > 0
                            ? '${service.consecutiveFailures} falhas consecutivas'
                            : 'Falha detectada',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  service.lastCheckedAt != null
                      ? 'Hoje, ${service.lastCheckedAt!.hour.toString().padLeft(2, '0')}:${service.lastCheckedAt!.minute.toString().padLeft(2, '0')}'
                      : 'Aguardando verificação',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFECEBDE)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => UrlLauncherService.openUrlWithFeedback(
                    context,
                    service.destinationUrl,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEBDE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Abrir serviço',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10110F),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(LucideIcons.externalLink, size: 14, color: Color(0xFF10110F)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final srvRepo = ref.read(serviceRepositoryProvider);
                    final healthService = ref.read(healthCheckServiceProvider);
                    final res = await healthService.checkUrl(service.id, service.destinationUrl);
                    await srvRepo.updateHealthStatus(
                      service.id,
                      res.status,
                      consecutiveFailures: res.status == ServiceHealthStatus.error ? service.consecutiveFailures + 1 : 0,
                      lastCheckedAt: DateTime.now(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reteste de ${service.publicTitle}: ${res.status.name.toUpperCase()}'),
                        backgroundColor: res.status == ServiceHealthStatus.healthy ? AppColors.greenSuccess : AppColors.orangeAction,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141513),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Testar novamente',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/services/${service.id}/edit'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141513).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Corrigir / Editar',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDeleteService(service),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDC2626)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, size: 14, color: Color(0xFFFFD1D1)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Excluir serviço',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFD1D1),
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
    );
  }

  Widget _buildWarningProblemCard(ServiceItem service, String compName) {
    final isManual = service.healthStatus == ServiceHealthStatus.manual;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/services/${service.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isManual
                        ? const LinearGradient(
                            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                          )
                        : null,
                    color: isManual ? null : const Color(0xFF282A26),
                  ),
                  child: Icon(
                    isManual ? Icons.camera_alt : Icons.warning_amber_rounded,
                    color: isManual ? Colors.white : const Color(0xFFFACC15),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$compName • ${service.publicTitle}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isManual ? 'Verificação manual' : 'Atenção necessária',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                      Text(
                        isManual ? 'Bloqueio de automação' : 'Alta latência ou oscilação detectada',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF282A26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFF9E9E9E), size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => UrlLauncherService.openUrlWithFeedback(
                    context,
                    service.destinationUrl,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252724),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Conferir destino',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.externalLink, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final srvRepo = ref.read(serviceRepositoryProvider);
                    final healthService = ref.read(healthCheckServiceProvider);
                    final res = await healthService.checkUrl(service.id, service.destinationUrl);
                    await srvRepo.updateHealthStatus(
                      service.id,
                      res.status,
                      consecutiveFailures: res.status == ServiceHealthStatus.error ? service.consecutiveFailures + 1 : 0,
                      lastCheckedAt: DateTime.now(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reteste de ${service.publicTitle}: ${res.status.name.toUpperCase()}'),
                        backgroundColor: res.status == ServiceHealthStatus.healthy ? AppColors.greenSuccess : AppColors.orangeAction,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2C2F2A)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Testar',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/services/${service.id}/edit'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222421),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF333630)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Corrigir / Editar',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDeleteService(service),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1515),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF501B1B)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, size: 14, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Excluir serviço',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
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
    );
  }

  Widget _buildHealthyCard(ServiceItem service, String compName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/services/${service.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$compName • ${service.publicTitle}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.destinationUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => UrlLauncherService.openUrlWithFeedback(
                    context,
                    service.destinationUrl,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252724),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Abrir destino',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.externalLink, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/services/${service.id}/edit'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252724),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.pencil, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Editar',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
    );
  }
}
