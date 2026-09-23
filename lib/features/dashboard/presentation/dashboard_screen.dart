import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/order_item.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';
import '../../inventory/presentation/widgets/nfc_scan_modal.dart';

/// Tela S02 — Dashboard / Início do NFC Ops.
/// Reproduz estritamente a prancha 01 (layout, cores neo-grotesk, métricas e pendências reais).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isTestingServices = false;

  Future<void> _handleTestServices() async {
    setState(() => _isTestingServices = true);
    try {
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final healthService = ref.read(healthCheckServiceProvider);
      final services = await serviceRepo.getAllServices();
      if (services.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum serviço cadastrado para testar. Cadastre uma empresa e serviço primeiro.'),
            backgroundColor: AppColors.orangeAction,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      int tested = 0;
      for (final s in services.take(5)) {
        final result = await healthService.checkUrl(s.id, s.destinationUrl);
        await serviceRepo.updateHealthStatus(
          s.id,
          result.status,
          consecutiveFailures: result.status == ServiceHealthStatus.error ? s.consecutiveFailures + 1 : 0,
          lastCheckedAt: DateTime.now(),
        );
        tested++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$tested serviços verificados com sucesso! Status atualizados.'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao executar verificação: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingServices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);
    final ordersAsync = ref.watch(ordersStreamProvider);

    final services = servicesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];
    final orders = ordersAsync.value ?? [];

    final healthyCount = services.where((s) => s.healthStatus == ServiceHealthStatus.healthy).length;
    final warningCount = services.where((s) => s.healthStatus == ServiceHealthStatus.warning).length;
    final errorCount = services.where((s) => s.healthStatus == ServiceHealthStatus.error).length;
    final manualCount = services.where((s) => s.healthStatus == ServiceHealthStatus.manual).length;
    final criticalCount = errorCount;

    final totalServices = services.length;
    final totalCompanies = companies.length;
    final healthRatio = totalServices > 0 ? (healthyCount / totalServices) : 0.0;
    final healthPercent = (healthRatio * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabeçalho com perfil Gustavo e sino
              NfcAppHeader(
                userName: user != null && user.displayName.isNotEmpty
                    ? user.displayName.split(' ').first
                    : 'Gustavo',
                userInitial: user != null && user.displayName.isNotEmpty
                    ? user.displayName[0]
                    : 'G',
                onNotificationTap: () => context.push('/activities'),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 31),

                    // 2. Título principal
                    const Text(
                      'Tudo sob controle?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 17),

                    // 3. Card Laranja Proeminente (só existe se realmente houver problema crítico)
                    if (criticalCount > 0) ...[
                      _buildCriticalAlertCard(context, criticalCount),
                      const SizedBox(height: 11),
                    ],

                    // 4. Dois cards lado a lado (Lilás: Serviços ativos | Creme: Empresas)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            backgroundColor: const Color(0xFF9FA7FC),
                            icon: LucideIcons.layers,
                            count: '$totalServices',
                            label: 'serviços ativos',
                            onTap: () => context.push('/health'),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _buildMetricCard(
                            backgroundColor: AppColors.surfaceCream,
                            icon: Icons.apartment,
                            count: '$totalCompanies',
                            label: 'empresas',
                            onTap: () => context.go('/companies'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    // 5. Card largo de resumo de saúde com métricas reais
                    _buildHealthSummaryCard(
                      context,
                      totalServices: totalServices,
                      healthyCount: healthyCount,
                      warningCount: warningCount,
                      errorCount: errorCount,
                      manualCount: manualCount,
                      healthRatio: healthRatio,
                      healthPercent: healthPercent,
                    ),

                    const SizedBox(height: 14),

                    // Card de Ação Rápida: Escanear Placa NFC
                    InkWell(
                      onTap: () => NfcScanModal.show(context, companies: companies),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1D1B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.orangeAction.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.radio, color: AppColors.orangeAction, size: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Escanear Placa NFC',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Aproxime uma tag para identificar ou cadastrar',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF9E9E9E),
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

                    const SizedBox(height: 21),

                    // 6. Seção Pendências reais de pedidos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pendências',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/orders'),
                          child: const Row(
                            children: [
                              Text(
                                'Ver todas',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.chevron_right, size: 15, color: Color(0xFF8E8E93)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Lista dinâmica de pendências do banco
                    if (orders.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1B19),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF262824)),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhuma pendência operacional no momento.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF8E8E93)),
                          ),
                        ),
                      )
                    else
                      ...orders.take(3).map((order) {
                        final orderNum = order.orderNumber.replaceAll('#', '').isNotEmpty
                            ? order.orderNumber.replaceAll('#', '')
                            : order.id.replaceAll(RegExp(r'[^0-9]'), '');
                        final displayNum = orderNum.isNotEmpty ? orderNum : order.id;
                        final isFinished = order.status == OrderStatus.entregue || order.status == OrderStatus.pronto;

                        String statusLabel;
                        switch (order.status) {
                          case OrderStatus.testes:
                            statusLabel = 'Aguardando testes';
                            break;
                          case OrderStatus.pronto:
                            statusLabel = 'Pronto para entrega';
                            break;
                          case OrderStatus.producao:
                            statusLabel = 'Em produção';
                            break;
                          case OrderStatus.entregue:
                            statusLabel = 'Entregue';
                            break;
                          case OrderStatus.aguardandoAprovacao:
                            statusLabel = 'Aguardando aprovação';
                            break;
                          case OrderStatus.aprovado:
                            statusLabel = 'Aprovado';
                            break;
                          case OrderStatus.orcamento:
                            statusLabel = 'Orçamento';
                            break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: _buildPendingOrderItem(
                            context: context,
                            orderNumber: displayNum,
                            statusText: statusLabel,
                            iconBgColor: isFinished ? const Color(0xFF77E537) : const Color(0xFFFC6B1A),
                            icon: isFinished ? Icons.check_circle : Icons.access_time_rounded,
                            orderId: order.id,
                          ),
                        );
                      }),

                    const SizedBox(height: 9),

                    // 7. Botão Primário Verde-Limão: "Testar serviços"
                    Semantics(
                      button: true,
                      label: 'Testar serviços',
                      child: Material(
                        color: const Color(0xFF96F044),
                        borderRadius: BorderRadius.circular(25),
                        child: InkWell(
                          onTap: _isTestingServices ? null : _handleTestServices,
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: _isTestingServices
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF10110F),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Color(0xFF10110F),
                                        size: 22,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Testar serviços',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15.5,
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
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAlertCard(BuildContext context, int criticalCount) {
    final hasProblems = criticalCount > 0;
    return InkWell(
      onTap: () => context.push('/health'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 122,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: hasProblems ? AppColors.orangeAction : const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(24),
          border: hasProblems ? null : Border.all(color: const Color(0xFF2E312C)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: hasProblems ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF2E312C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  hasProblems ? Icons.priority_high_rounded : Icons.check_circle_outline,
                  color: hasProblems ? Colors.white : const Color(0xFF22C55E),
                  size: 28,
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
                    hasProblems
                        ? '$criticalCount problema${criticalCount > 1 ? 's' : ''}'
                        : 'Operação estável',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    hasProblems ? 'crítico${criticalCount > 1 ? 's' : ''}' : '100% monitorada',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasProblems ? 'Revisar agora' : 'Ver central de saúde',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFECEBDE),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF161715),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required Color backgroundColor,
    required IconData icon,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 115,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF10110F)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10110F),
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10110F),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10110F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummaryCard(
    BuildContext context, {
    required int totalServices,
    required int healthyCount,
    required int warningCount,
    required int errorCount,
    required int manualCount,
    required double healthRatio,
    required int healthPercent,
  }) {
    return InkWell(
      onTap: () => context.push('/health'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCream,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Status geral dos serviços',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10110F),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (totalServices == 0)
                    const Text(
                      'Nenhum serviço monitorado',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusDotItem('$healthyCount', 'saudáveis', const Color(0xFF4DC621)),
                          const SizedBox(width: 10),
                          _buildStatusDotItem('$warningCount', 'atenção', const Color(0xFFFACC15)),
                          const SizedBox(width: 10),
                          _buildStatusDotItem('$errorCount', 'erro', const Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          _buildStatusDotItem('$manualCount', 'manual', const Color(0xFF9CA3AF)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: CircularProgressIndicator(
                      value: totalServices > 0 ? healthRatio : 0.0,
                      strokeWidth: 8.5,
                      backgroundColor: const Color(0xFFDCDBCF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalServices > 0 ? const Color(0xFF4DC621) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Text(
                    totalServices > 0 ? '$healthPercent%' : '—',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10110F),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDotItem(String count, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              count,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10110F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOrderItem({
    required BuildContext context,
    required String orderNumber,
    required String statusText,
    required Color iconBgColor,
    IconData? icon,
    Widget? customIcon,
    required String orderId,
  }) {
    return InkWell(
      onTap: () => context.push('/orders/$orderId'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 59,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B19),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF262824),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: customIcon ??
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pedido #$orderNumber',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
