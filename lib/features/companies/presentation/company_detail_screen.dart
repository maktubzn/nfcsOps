import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/company.dart';
import '../../../../core/models/order_item.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';
import '../../auth/presentation/widgets/google_logo.dart';
import 'widgets/company_card_icons.dart';

/// Tela S05 — Detalhe da Empresa ("Auto Center Silva").
/// Prancha 02 (design/02-empresa-e-servicos.png).
/// Mapeamento rigoroso pixel-a-pixel:
/// - Cabeçalho: NFC Ops Wordmark + Sino com badge
/// - Card 1: Identidade da empresa (Fundo creme #F3F0E6, avatar ferramentas 74x74, botão editar 44x44)
/// - Card 2: Contato (Responsável Carlos Silva | WhatsApp)
/// - Abas horizontais: Visão geral | Serviços (Ativa laranja #FF4F0A) | Dispositivos | Pedidos | Histórico
/// - Lista de Serviços conectados (Google Reviews, Instagram, WhatsApp, Localização)
/// - Botão primário "+ Adicionar serviço" (Laranja #FF4F0A)
/// - Botão secundário "▶ Testar todos" (#1C1D1B)
/// - Barra de navegação inferior padrão (Aba Empresas ativa em amarelo)
class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  int _selectedTabIndex = 1; // 0: Visão geral, 1: Serviços (canônico no design), 2: Dispositivos, 3: Pedidos, 4: Histórico
  bool _isTestingAll = false;
  bool _sortAlphabetical = false;

  String _formatCityUf(Company company) {
    if (company.city != null && company.city!.trim().isNotEmpty) {
      final c = company.city!.trim();
      if (c.contains('/')) return c;
      return '$c / SP';
    }
    return 'Brasil';
  }

  String _formatHealthSubtitle(ServiceItem service) {
    final statusLabel = switch (service.healthStatus) {
      ServiceHealthStatus.healthy => 'Saudável',
      ServiceHealthStatus.warning => 'Atenção',
      ServiceHealthStatus.error => 'Erro',
      ServiceHealthStatus.manual => 'Manual',
    };

    if (service.lastCheckedAt == null) {
      return '$statusLabel • Aguardando teste';
    }

    final dt = service.lastCheckedAt!;
    final now = DateTime.now();
    final diff = now.difference(dt);

    String timeStr;
    if (diff.inMinutes < 2) {
      timeStr = 'Agora há pouco';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      timeStr = 'Hoje, $h:$m';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final mon = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      timeStr = '$d/$mon, $h:$m';
    }

    return '$statusLabel • $timeStr';
  }

  Color _getStatusColor(ServiceHealthStatus status) {
    return switch (status) {
      ServiceHealthStatus.healthy => const Color(0xFF22C55E),
      ServiceHealthStatus.warning => const Color(0xFFFACC15),
      ServiceHealthStatus.error => const Color(0xFFEF4444),
      ServiceHealthStatus.manual => const Color(0xFF9E9E9E),
    };
  }

  (Color, String) _orderStatusBadge(OrderStatus status) {
    return switch (status) {
      OrderStatus.orcamento => (const Color(0xFF9E9E9E), 'Orçamento'),
      OrderStatus.aguardandoAprovacao => (const Color(0xFFF59E0B), 'Aguardando'),
      OrderStatus.aprovado => (const Color(0xFF3B82F6), 'Aprovado'),
      OrderStatus.producao => (const Color(0xFF8B5CF6), 'Produção'),
      OrderStatus.testes => (const Color(0xFFEC4899), 'Testes'),
      OrderStatus.pronto => (const Color(0xFF10B981), 'Pronto'),
      OrderStatus.entregue => (const Color(0xFF22C55E), 'Entregue'),
    };
  }

  Future<void> _handleTestAll(List<ServiceItem> services) async {
    setState(() => _isTestingAll = true);
    try {
      final srvRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);

      int count = 0;
      for (final s in services) {
        final res = await healthService.checkUrl(s.id, s.destinationUrl);
        await srvRepo.updateHealthStatus(
          s.id,
          res.status,
          consecutiveFailures: res.status == ServiceHealthStatus.error ? s.consecutiveFailures + 1 : 0,
          lastCheckedAt: DateTime.now(),
        );
        count++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count serviços testados com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao testar serviços: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingAll = false);
    }
  }

  Future<void> _handleTestSingle(ServiceItem service) async {
    try {
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
          content: Text('Serviço "${service.publicTitle}" verificado: ${res.status.name.toUpperCase()}'),
          backgroundColor: res.status == ServiceHealthStatus.healthy ? AppColors.greenSuccess : AppColors.orangeAction,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar serviço: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);

    final allCompanies = companiesAsync.value ?? [];
    final company = allCompanies.where((c) => c.id == widget.companyId).firstOrNull;

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Empresa não encontrada', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Empresa não localizada no banco de dados.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final allServices = servicesAsync.value ?? [];
    final rawCompanyServices = allServices.where((s) => s.companyId == company.id).toList();

    // Ordenação canônica padrão do design S05: Google Reviews, Instagram, WhatsApp, Localização
    final companyServices = _sortAlphabetical
        ? (List<ServiceItem>.from(rawCompanyServices)..sort((a, b) => a.publicTitle.compareTo(b.publicTitle)))
        : (List<ServiceItem>.from(rawCompanyServices)
          ..sort((a, b) {
            const order = ['google', 'instagram', 'whatsapp', 'localizacao'];
            final aType = a.serviceType.toLowerCase();
            final bType = b.serviceType.toLowerCase();
            final aIdx = order.indexWhere((k) => aType.contains(k));
            final bIdx = order.indexWhere((k) => bType.contains(k));
            return (aIdx >= 0 ? aIdx : 99).compareTo(bIdx >= 0 ? bIdx : 99);
          }));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabeçalho com Wordmark NFC Ops e Sino (alinhado a 14px de margem)
              NfcAppHeader(
                showWordmark: true,
                padding: const EdgeInsets.fromLTRB(14, 25, 14, 0),
                waveIconWidth: 32,
                waveIconHeight: 48,
                onNotificationTap: () => context.push('/activities'),
              ),

              const SizedBox(height: 19),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Card Principal da Empresa (Warm Cream #F3F0E6, altura 104px)
                    _buildCompanyHeaderCard(context, company),

                    const SizedBox(height: 9),

                    // 3. Card de Contato: Responsável + WhatsApp (Warm Cream #F3F0E6, altura 66px)
                    _buildContactCard(context, company),

                    const SizedBox(height: 13),

                    // 4. Abas horizontais: Visão geral | Serviços (Ativa) | Dispositivos | Pedidos | Histórico
                    _buildHorizontalTabs(),

                    const SizedBox(height: 16),

                    // Conteúdo dinâmico de acordo com a aba selecionada
                    if (_selectedTabIndex == 1) ...[
                      // 5. Título da Seção: Serviços
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Serviços',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${companyServices.length} serviços conectados',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF9E9E9E),
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() => _sortAlphabetical = !_sortAlphabetical);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  LucideIcons.listFilter,
                                  color: _sortAlphabetical ? AppColors.orangeAction : const Color(0xFF9E9E9E),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 6. Lista de Serviços (Cards calibrados ao pixel do design)
                      _buildServiceRows(companyServices),

                      const SizedBox(height: 10),

                      // 7. Botão Laranja: "+ Adicionar serviço" (altura 46px)
                      Semantics(
                        button: true,
                        label: 'Adicionar serviço',
                        child: Material(
                          color: AppColors.orangeAction,
                          borderRadius: BorderRadius.circular(23),
                          child: InkWell(
                            onTap: () => context.push('/services/new?companyId=${company.id}'),
                            borderRadius: BorderRadius.circular(23),
                            child: Container(
                              height: 46,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Adicionar serviço',
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
                      ),

                      const SizedBox(height: 8),

                      // 8. Botão Secundário Dark: "▶ Testar todos" (altura 43px)
                      Material(
                        color: const Color(0xFF1C1D1B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: const BorderSide(color: Color(0xFF282A26), width: 1),
                        ),
                        child: InkWell(
                          onTap: _isTestingAll ? null : () => _handleTestAll(companyServices),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            height: 43,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: _isTestingAll
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Testar todos',
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
                      const SizedBox(height: 16),
                    ] else if (_selectedTabIndex == 0) ...[
                      // Aba Visão Geral
                      _buildGeneralTab(context, company),
                    ] else if (_selectedTabIndex == 2) ...[
                      // Aba Dispositivos
                      _buildDevicesTab(context, company),
                    ] else if (_selectedTabIndex == 3) ...[
                      // Aba Pedidos
                      _buildOrdersTab(context, company),
                    ] else ...[
                      // Aba Histórico
                      _buildHistoryTab(context, company),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeaderCard(BuildContext context, Company company) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Laranja 74x74 com ferramentas cruzadas pretas
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: AppColors.orangeAction,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CrossedWrenchesWidget(
                color: Color(0xFF10110F),
                size: 38,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  company.tradeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10110F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${company.category} • ${_formatCityUf(company)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ativa',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botão Editar 44x44
          InkWell(
            onTap: () => context.push('/companies/${company.id}/edit'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFDCDBCF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF10110F),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Company company) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lado Esquerdo: Responsável
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10110F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.contactName ?? 'Carlos Silva',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10110F),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Responsável',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divisor Vertical
          Container(height: 26, width: 1, color: const Color(0xFFDCDBCF)),
          const SizedBox(width: 14),

          // Lado Direito: Ação WhatsApp
          InkWell(
            onTap: () => UrlLauncherService.openWhatsAppWithFeedback(
              context,
              company.phone,
            ),
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.messageCircle, color: Color(0xFF22C55E), size: 20),
                SizedBox(width: 6),
                Text(
                  'WhatsApp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10110F),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF10110F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabs() {
    final tabs = ['Visão geral', 'Serviços', 'Dispositivos', 'Pedidos', 'Histórico'];
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Padding(
              padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = index),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orangeAction : const Color(0xFF1C1D1B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? AppColors.orangeAction : const Color(0xFF282A26),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildServiceRows(List<ServiceItem> services) {
    if (services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF161715),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: const Center(
          child: Text(
            'Nenhum serviço cadastrado para esta empresa.\nToque em "+ Adicionar serviço" abaixo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Column(
      children: services.asMap().entries.map((entry) {
        final idx = entry.key;
        final service = entry.value;
        final type = service.serviceType.toLowerCase();

        Widget logo;
        String title;
        String subtitle;
        Color statusColor;
        bool isGoogleReview = false;
        bool isInstagram = false;

        if (type.contains('google') || type.contains('review')) {
          isGoogleReview = true;
          title = 'Google Reviews';
          logo = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: GoogleLogo(size: 20)),
          );
        } else if (type.contains('instagram')) {
          isInstagram = true;
          title = 'Instagram';
          logo = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          );
        } else if (type.contains('whatsapp')) {
          title = 'WhatsApp';
          logo = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(LucideIcons.messageCircle, color: Colors.white, size: 22),
            ),
          );
        } else if (type.contains('localizacao') || type.contains('maps')) {
          title = 'Localização';
          logo = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.location_on, color: Color(0xFFEF4444), size: 24),
            ),
          );
        } else {
          title = service.publicTitle.isNotEmpty ? service.publicTitle : service.serviceType;
          logo = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF222421),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(LucideIcons.globe, color: AppColors.orangeAction, size: 22),
            ),
          );
        }

        subtitle = _formatHealthSubtitle(service);
        statusColor = _getStatusColor(service.healthStatus);

        const cardHeight = 64.0;
        return Padding(
          padding: EdgeInsets.only(bottom: idx < services.length - 1 ? 6 : 0),
          child: _buildServiceCard(
            height: cardHeight,
            title: title,
            subtitle: subtitle,
            statusColor: statusColor,
            logo: logo,
            isGoogleReview: isGoogleReview,
            isInstagram: isInstagram,
            onTap: () => context.push('/services/${service.id}'),
            onOpen: () => UrlLauncherService.openUrlWithFeedback(context, service.destinationUrl),
            onTest: () => _handleTestSingle(service),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard({
    required double height,
    required String title,
    required String subtitle,
    required Color statusColor,
    required Widget logo,
    required bool isGoogleReview,
    required bool isInstagram,
    required VoidCallback onTap,
    required VoidCallback onOpen,
    required VoidCallback onTest,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: statusColor == const Color(0xFF9E9E9E) ? const Color(0xFF9E9E9E) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Ações específicas conforme referência visual canônica:
            // Ações: Botão "Abrir" (52x34) e Botão "Testar" (58x34)
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 52,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF202221),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Text(
                  'Abrir',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onTest,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 58,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6DDB39),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Text(
                  'Testar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10110F),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, Company company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161715),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF282A26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados Cadastrais',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Razão Social', company.legalName ?? company.tradeName),
          _buildInfoRow('CNPJ', company.document ?? 'Não informado'),
          _buildInfoRow('Categoria', company.category),
          if (company.notes != null && company.notes!.trim().isNotEmpty)
            _buildInfoRow('Endereço', company.notes!.trim()),
          _buildInfoRow('Cidade / UF', _formatCityUf(company)),
          _buildInfoRow('E-mail', company.email ?? 'Não informado'),
          _buildInfoRow('Telefone', company.phone ?? 'Não informado'),
          _buildInfoRow('Status', company.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab(BuildContext context, Company company) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final allDevices = devicesAsync.value ?? [];
    final companyDevices = allDevices.where((d) => d.assignedCompanyId == company.id).toList();

    if (companyDevices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161715),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: const Center(
          child: Text(
            'Nenhum dispositivo associado a esta empresa.',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: companyDevices.map((dev) {
        return InkWell(
          onTap: () => context.push('/inventory/${dev.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1D1B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF282A26)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.smartphone, color: AppColors.orangeAction, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dev.deviceType,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'ID: ${dev.id} • Lote: ${dev.batchId} • ${dev.status.name}',
                        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdersTab(BuildContext context, Company company) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final allOrders = ordersAsync.value ?? [];
    final companyOrders = allOrders.where((o) => o.companyId == company.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${companyOrders.length} pedido${companyOrders.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => context.push('/orders/new?companyId=${company.id}'),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Novo pedido', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAction,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (companyOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF161715),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF282A26)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.orangeAction.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.shoppingBag, color: AppColors.orangeAction, size: 24),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nenhum pedido registrado',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cadastre o primeiro pedido de placas NFC ou cartões para esta empresa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/orders/new?companyId=${company.id}'),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Criar primeiro pedido', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeAction,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          )
        else
          ...companyOrders.map((order) {
            final (statusColor, statusLabel) = _orderStatusBadge(order.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.push('/orders/${order.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1D1B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF282A26)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF242623),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.shoppingBag, color: AppColors.orangeAction, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Pedido #${order.orderNumber}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    statusLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.items.length} ite${order.items.length == 1 ? 'm' : 'ns'} • Total: R\$ ${(order.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF9E9E9E),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, Company company) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final allActivities = activitiesAsync.value ?? [];
    final companyActivities = allActivities.where((a) => a.entityId == company.id).toList();

    if (companyActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161715),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: const Center(
          child: Text(
            'Nenhuma atividade recente registrada.',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: companyActivities.map((act) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF282A26)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.history, color: AppColors.orangeAction, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.description,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${act.timestamp.day.toString().padLeft(2, '0')}/${act.timestamp.month.toString().padLeft(2, '0')}/${act.timestamp.year}',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
