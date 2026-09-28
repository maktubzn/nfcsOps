import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal A01 — Ações Rápidas (Bottom Sheet "O que vamos criar?")
class QuickActionsModal extends StatelessWidget {
  const QuickActionsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const QuickActionsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161715),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF282A26), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrasto superior
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF383B36),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Cabeçalho: Título + Fechar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'O que vamos criar?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF222421),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opção 1: Nova empresa
            _buildActionTile(
              context: context,
              icon: LucideIcons.building2,
              title: 'Nova empresa',
              subtitle: 'Cadastrar cliente, categoria e contato',
              iconColor: AppColors.orangeAction,
              iconBgColor: AppColors.orangeAction.withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/companies/new');
              },
            ),

            const SizedBox(height: 12),

            // Opção 2: Novo serviço
            _buildActionTile(
              context: context,
              icon: LucideIcons.layers,
              title: 'Novo serviço',
              subtitle: 'Criar link, Google Reviews, QR e destino',
              iconColor: const Color(0xFFA5ADEB),
              iconBgColor: const Color(0xFFA5ADEB).withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/services/new');
              },
            ),

            const SizedBox(height: 12),

            // Opção 3: Novo pedido
            _buildActionTile(
              context: context,
              icon: LucideIcons.shoppingBag,
              title: 'Novo pedido',
              subtitle: 'Placas, cartões e configuração comercial',
              iconColor: const Color(0xFF96F044),
              iconBgColor: const Color(0xFF96F044).withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/orders/new');
              },
            ),

            const SizedBox(height: 12),

            // Opção 4: Novo dispositivo
            _buildActionTile(
              context: context,
              icon: LucideIcons.cpu,
              title: 'Novo dispositivo',
              subtitle: 'Registrar placa NFC ou cartão no estoque',
              iconColor: const Color(0xFFFACC15),
              iconBgColor: const Color(0xFFFACC15).withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/inventory/new');
              },
            ),

            const SizedBox(height: 12),

            // Opção 5: Criar Placa para Empresa
            _buildActionTile(
              context: context,
              icon: LucideIcons.printer,
              title: 'Criar placa com QR',
              subtitle: 'Gerar arte personalizada para uma empresa',
              iconColor: const Color(0xFF38BDF8),
              iconBgColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/designs/generate');
              },
            ),

            const SizedBox(height: 12),

            // Opção 6: Novo Modelo de Placa
            _buildActionTile(
              context: context,
              icon: LucideIcons.layoutTemplate,
              title: 'Novo modelo de placa',
              subtitle: 'Upload de arte e posicionamento de QR Code',
              iconColor: const Color(0xFFF472B6),
              iconBgColor: const Color(0xFFF472B6).withValues(alpha: 0.15),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/templates/new');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF2C2F2A),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF8E918F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
