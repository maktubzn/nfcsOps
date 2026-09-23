import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/activity_entry.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S15 — Atividades / Histórico Operacional do NFC Ops.
class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final activities = activitiesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Expanded(
                    child: Text(
                      'Atividades recentes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: activities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.activity, color: Colors.white.withValues(alpha: 0.3), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhuma atividade recente',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ações operacionais aparecerão aqui em tempo real.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: activities.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final config = _getActivityDisplayConfig(act);
                        VoidCallback? onTap;
                        if (act.entityId.isNotEmpty) {
                          if (act.entityType == 'company') {
                            onTap = () => context.push('/companies/${act.entityId}');
                          } else if (act.entityType == 'order') {
                            onTap = () => context.push('/orders/${act.entityId}');
                          } else if (act.entityType == 'device') {
                            onTap = () => context.push('/inventory/${act.entityId}');
                          } else if (act.entityType == 'service') {
                            onTap = () => context.push('/services/${act.entityId}');
                          }
                        }
                        return _buildActivityItem(
                          icon: config.icon,
                          iconBg: config.color,
                          title: config.title,
                          desc: act.description.isNotEmpty ? act.description : 'Ação realizada por ${act.actorName}',
                          time: _formatTimestamp(act.timestamp),
                          onTap: onTap,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  _ActivityDisplay _getActivityDisplayConfig(ActivityEntry act) {
    if (act.entityType == 'order' || act.actionType.contains('order')) {
      return const _ActivityDisplay(
        icon: LucideIcons.shoppingBag,
        color: Color(0xFFFACC15),
        title: 'Pedido registrado',
      );
    }
    if (act.entityType == 'company' || act.actionType.contains('company')) {
      return const _ActivityDisplay(
        icon: LucideIcons.building2,
        color: Color(0xFFA5ADEB),
        title: 'Empresa atualizada',
      );
    }
    if (act.entityType == 'device' || act.actionType.contains('checklist')) {
      return const _ActivityDisplay(
        icon: LucideIcons.checkSquare,
        color: AppColors.orangeAction,
        title: 'Checklist físico',
      );
    }
    return const _ActivityDisplay(
      icon: LucideIcons.playCircle,
      color: Color(0xFF22C55E),
      title: 'Verificação de links',
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0 && now.day == dt.day) {
      return 'Hoje, $timeStr';
    } else if (diff.inDays <= 1) {
      return 'Ontem, $timeStr';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} $timeStr';
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String desc,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityDisplay {
  final IconData icon;
  final Color color;
  final String title;

  const _ActivityDisplay({
    required this.icon,
    required this.color,
    required this.title,
  });
}
