import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela S16 — Configurações e Gestão Operacional do NFC Ops.
/// Fiel à Prancha 04 (design/04-pedidos-e-gestao.png).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _monitoringFrequency = 'Diariamente';
  int _consecutiveFailuresThreshold = 3;
  int _lowStockThreshold = 5;

  void _showCatalogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final catalog = [
          {'name': 'Google Reviews', 'desc': 'Avaliação direta no Google Perfil da Empresa', 'active': true},
          {'name': 'Instagram', 'desc': 'Abertura do perfil no aplicativo Instagram', 'active': true},
          {'name': 'WhatsApp Comercial', 'desc': 'Início de conversa com mensagem predefinida', 'active': true},
          {'name': 'Cardápio Digital', 'desc': 'Link para cardápio em PDF ou webapp', 'active': true},
          {'name': 'Wi-Fi Convidado', 'desc': 'Conexão automática à rede Wi-Fi local', 'active': true},
          {'name': 'Chave PIX', 'desc': 'Cópia rápida de chave ou checkout instantâneo', 'active': true},
          {'name': 'Avaliação de Balcão', 'desc': 'Formulário interno de satisfação do cliente', 'active': true},
          {'name': 'Agendamento Online', 'desc': 'Integração com agenda ou sistema de reservas', 'active': true},
          {'name': 'Catálogo de Produtos', 'desc': 'Vitrine virtual para lojas e varejo', 'active': true},
          {'name': 'Clube de Fidelidade', 'desc': 'Registro de pontos ou carimbo virtual', 'active': true},
          {'name': 'Link Tree / Bio', 'desc': 'Hub de links múltiplos da empresa', 'active': true},
          {'name': 'Destino Personalizado', 'desc': 'Qualquer URL HTTPS customizada', 'active': true},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Catálogo de Serviços',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  '12 tipos de integrações ativas no NFC Ops',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: catalog.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF242623), height: 1),
                    itemBuilder: (ctx, i) {
                      final item = catalog[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF202220),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.box, color: AppColors.orangeAction, size: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  Text(
                                    item['desc'] as String,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoriesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final categories = [
          'Oficina Mecânica / Auto Center',
          'Cafeteria / Coffee Shop',
          'Restaurante / Hamburgueria',
          'Barbearia / Salão Masculino',
          'Pet Shop / Clínica Veterinária',
          'Estética / Salão de Beleza',
          'Varejo / Moda e Vestuário',
          'Saúde / Odontologia / Consultório',
          'Academia / Crossfit / Estúdio',
          'Serviços Gerais / Outros',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Categorias de Empresas',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sugestões automáticas aplicadas na criação de empresas',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF242623), height: 1),
                    itemBuilder: (ctx, i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.tag, color: Colors.white, size: 18),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                categories[i],
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonitoringDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Frequência de Monitoramento', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
        children: ['A cada 1 hora', 'A cada 6 horas', 'Diariamente', 'Semanalmente'].map((opt) {
          final isSelected = _monitoringFrequency == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _monitoringFrequency = opt);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Monitoramento atualizado para: $opt'), backgroundColor: AppColors.greenSuccess),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opt, style: TextStyle(color: isSelected ? AppColors.orangeAction : Colors.white, fontFamily: 'Inter')),
                if (isSelected) const Icon(Icons.check, color: AppColors.orangeAction, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showThresholdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Limiar de Falhas para Sinalizar Erro', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
        children: [1, 2, 3, 5].map((count) {
          final isSelected = _consecutiveFailuresThreshold == count;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _consecutiveFailuresThreshold = count);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Limiar de falhas atualizado para $count consecutivas'), backgroundColor: AppColors.greenSuccess),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$count falha${count > 1 ? 's' : ''} consecutiva${count > 1 ? 's' : ''}',
                    style: TextStyle(color: isSelected ? AppColors.orangeAction : Colors.white, fontFamily: 'Inter')),
                if (isSelected) const Icon(Icons.check, color: AppColors.orangeAction, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStockAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Alerta de Estoque Mínimo', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
        children: [3, 5, 10, 20].map((qty) {
          final isSelected = _lowStockThreshold == qty;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _lowStockThreshold = qty);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Alerta de estoque configurado para menos de $qty unidades'), backgroundColor: AppColors.greenSuccess),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menos de $qty unidades', style: TextStyle(color: isSelected ? AppColors.orangeAction : Colors.white, fontFamily: 'Inter')),
                if (isSelected) const Icon(Icons.check, color: AppColors.orangeAction, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAuthorizedUsersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final users = [
          {'name': 'Gustavo Alves', 'email': 'gustwwavomitopai@gmail.com', 'role': 'Administrador Geral', 'active': true},
          {'name': 'Operador Técnico', 'email': 'operador@nfcops.com', 'role': 'Operador de Campo', 'active': true},
          {'name': 'Suporte Produção', 'email': 'producao@nfcops.com', 'role': 'Técnico de Produção', 'active': true},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Usuários Autorizados',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Perfis com permissão de acesso ao sistema e ao banco Cloud Firestore',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF242623), height: 1),
                    itemBuilder: (ctx, i) {
                      final u = users[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF242623),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (u['name'] as String)[0],
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['name'] as String,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  Text(
                                    '${u['email']} • ${u['role']}',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ATIVO',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D1B),
        title: const Text('Sair da conta?', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text(
          'Você precisará fazer login novamente com sua conta Google autorizada para acessar o sistema.',
          style: TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final initial = user != null && user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'G';
    final displayName = user != null && user.displayName.isNotEmpty
        ? user.displayName.split(' ').first
        : 'Gustavo';
    final role = user?.role == 'admin' ? 'Administrador' : 'Operador';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Seta voltar + Título "Configurações"
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1D1B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Card do Perfil (Dark #161715 com Avatar e chevron)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161715),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF242623)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF222422),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção Operação
              const Text(
                'Operação',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Grupo de Itens: Operação
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161715),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF242623)),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: LucideIcons.box,
                      iconColor: AppColors.orangeAction,
                      title: 'Catálogo de serviços',
                      subtitle: '12 tipos ativos',
                      onTap: () => _showCatalogModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.tag,
                      iconColor: Colors.white,
                      title: 'Categorias e sugestões',
                      onTap: () => _showCategoriesModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.monitor,
                      iconColor: Colors.white,
                      title: 'Monitoramento',
                      subtitle: _monitoringFrequency,
                      onTap: () => _showMonitoringDialog(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.alertTriangle,
                      iconColor: Colors.white,
                      title: 'Falhas para sinalizar erro',
                      subtitle: '$_consecutiveFailuresThreshold consecutivas',
                      onTap: () => _showThresholdDialog(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.bell,
                      iconColor: Colors.white,
                      title: 'Alertas de estoque',
                      subtitle: 'Abaixo de $_lowStockThreshold un.',
                      onTap: () => _showStockAlertDialog(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.shoppingBag,
                      iconColor: AppColors.orangeAction,
                      title: 'Gestão de Pedidos',
                      subtitle: 'Ordens de serviço, produção e entrega',
                      onTap: () => context.push('/orders'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção Conta
              const Text(
                'Conta',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Grupo de Itens: Conta
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161715),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF242623)),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: LucideIcons.user,
                      iconColor: Colors.white,
                      title: 'Usuários autorizados',
                      onTap: () => _showAuthorizedUsersModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
                      icon: LucideIcons.logOut,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Sair da conta',
                      titleColor: const Color(0xFFEF4444),
                      onTap: () => _handleSignOut(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Versão do aplicativo no rodapé
              const Center(
                child: Text(
                  'NFC Ops • Versão 1.0',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Color(0xFF242623), height: 1),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color titleColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 18),
          ],
        ),
      ),
    );
  }
}
