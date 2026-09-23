import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/widgets/google_logo.dart';

/// Tela S07 — Detalhe do Serviço ("Google Reviews").
/// Exibe status de saúde, destino atual com cópia e abertura, dispositivo NFC associado e ações operacionais.
class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  bool _isTesting = false;

  Future<void> _handleTestNow(ServiceItem service) async {
    setState(() => _isTesting = true);
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
          content: Text('Teste concluído: status ${res.status.name.toUpperCase()} (resposta: 200 OK)'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _handleCopyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copiada para a área de transferência!'),
        backgroundColor: AppColors.greenSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final devicesAsync = ref.watch(devicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allServices = servicesAsync.value ?? [];
    final allDevices = devicesAsync.value ?? [];
    final allCompanies = companiesAsync.value ?? [];

    final service = allServices.where((s) => s.id == widget.serviceId).firstOrNull;

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

    final company = allCompanies.where((c) => c.id == service.companyId).firstOrNull;
    final companyName = company?.tradeName ?? 'Empresa';
    final companySubtitle = company != null
        ? '${company.category}${company.city != null ? ' • ${company.city}' : ''}'
        : 'NFC Ops';

    final linkedDevice = allDevices.where((d) {
      if (d.primaryServiceId != null && d.primaryServiceId == service.id) return true;
      return false;
    }).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top bar com seta de voltar, título e 3 pontinhos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => context.canPop() ? context.pop() : context.go('/companies/${service.companyId}'),
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
                    Text(
                      service.publicTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/services/${service.id}/edit'),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF222421),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
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
                    const SizedBox(height: 6),

                    // 2. Subheader: Logo, Company Name, Pill Ativo
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF222421),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: service.serviceType == 'google_reviews'
                                ? const GoogleLogo(size: 22)
                                : service.serviceType == 'whatsapp'
                                    ? const Icon(LucideIcons.messageCircle, color: Color(0xFF22C55E), size: 22)
                                    : const Icon(LucideIcons.globe, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                companySubtitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: service.status == 'ativo' ? const Color(0xFF22C55E) : const Color(0xFF4B5563),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            service.status == 'ativo' ? 'Ativo' : 'Inativo',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: service.status == 'ativo' ? const Color(0xFF10110F) : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Card Grande de Saúde (Warm Cream #ECEBDE)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: service.healthStatus == ServiceHealthStatus.healthy
                                  ? const Color(0xFF22C55E)
                                  : service.healthStatus == ServiceHealthStatus.warning
                                      ? const Color(0xFFFACC15)
                                      : service.healthStatus == ServiceHealthStatus.error
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              service.healthStatus == ServiceHealthStatus.healthy
                                  ? Icons.check
                                  : service.healthStatus == ServiceHealthStatus.warning
                                      ? Icons.warning_amber_rounded
                                      : service.healthStatus == ServiceHealthStatus.error
                                          ? Icons.priority_high
                                          : Icons.camera_alt,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.healthStatus == ServiceHealthStatus.healthy
                                      ? 'Saudável'
                                      : service.healthStatus == ServiceHealthStatus.warning
                                          ? 'Atenção'
                                          : service.healthStatus == ServiceHealthStatus.error
                                              ? 'Erro'
                                              : 'Verificação manual',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10110F),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.lastCheckedAt != null
                                      ? 'Último teste hoje, ${service.lastCheckedAt!.hour.toString().padLeft(2, '0')}:${service.lastCheckedAt!.minute.toString().padLeft(2, '0')}'
                                      : 'Aguardando verificação',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF10110F), size: 24),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Card Dark: "Destino atual"
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.link, size: 16, color: Color(0xFF9E9E9E)),
                              SizedBox(width: 8),
                              Text(
                                'Destino atual',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141513),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF222421)),
                            ),
                            child: Text(
                              service.destinationUrl,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Colors.white,
                              ),
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
                                        Icon(LucideIcons.externalLink, size: 16, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Abrir destino',
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _handleCopyUrl(service.destinationUrl),
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
                                        Icon(LucideIcons.copy, size: 16, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Copiar',
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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

                    const SizedBox(height: 12),

                    // 5. Faixa Lilás (#A5ADEB): Dispositivo Vinculado
                    InkWell(
                      onTap: () {
                        if (linkedDevice != null) {
                          context.push('/inventory/${linkedDevice.id}');
                        } else {
                          context.push('/inventory');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5ADEB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10110F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.cpu, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    linkedDevice != null
                                        ? (linkedDevice.batchId.isNotEmpty
                                            ? linkedDevice.batchId
                                            : linkedDevice.id)
                                        : 'Nenhum dispositivo associado',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10110F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    linkedDevice != null
                                        ? '${linkedDevice.deviceType} • Associado'
                                        : 'Toque para vincular placa/cartão do estoque',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF383B36),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF10110F), size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 6. Linhas de Ações: Ver QR Code, Histórico, Editar serviço
                    _buildActionRow(
                      icon: LucideIcons.qrCode,
                      label: 'Ver QR Code',
                      onTap: () => context.push('/qr/${service.id}'),
                    ),
                    const SizedBox(height: 8),
                    _buildActionRow(
                      icon: LucideIcons.clock,
                      label: 'Histórico',
                      onTap: () => context.push('/activities'),
                    ),
                    const SizedBox(height: 8),
                    _buildActionRow(
                      icon: LucideIcons.settings,
                      label: 'Editar serviço',
                      onTap: () => context.push('/services/${service.id}/edit'),
                    ),

                    const SizedBox(height: 20),

                    // 7. Botão Primário Laranja: "Testar agora"
                    Material(
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: _isTesting ? null : () => _handleTestNow(service),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: _isTesting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Testar agora',
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

                    // 8. Botão Secundário: "Desativar / Ativar"
                    Material(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () async {
                          final srvRepo = ref.read(serviceRepositoryProvider);
                          final newStatus = service.status == 'ativo' ? 'inativo' : 'ativo';
                          await srvRepo.updateService(service.copyWith(status: newStatus));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status do serviço atualizado para ${newStatus.toUpperCase()}!'),
                                backgroundColor: newStatus == 'ativo' ? AppColors.greenSuccess : AppColors.orangeAction,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.power, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                service.status == 'ativo' ? 'Desativar' : 'Ativar serviço',
                                style: const TextStyle(
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

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
