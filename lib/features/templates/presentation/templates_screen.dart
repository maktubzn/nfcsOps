import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/plate_template.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nfc_app_header.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  String _selectedCategory = 'todos';

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesStreamProvider);
    final allTemplates = templatesAsync.value ?? [];

    final filtered = allTemplates.where((t) {
      if (_selectedCategory == 'todos') return true;
      if (_selectedCategory == 'canva') return t.isCanva;
      if (_selectedCategory == 'internos') return !t.isCanva;
      return t.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NfcAppHeader(
                showWordmark: true,
                onNotificationTap: () => context.push('/activities'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modelos de Placas',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Templates visuais com QR Code integrado.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Filtros de categoria
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('Todos', 'todos'),
                          const SizedBox(width: 8),
                          _buildFilterPill('🎨 Canva', 'canva'),
                          const SizedBox(width: 8),
                          _buildFilterPill('📐 Internos', 'internos'),
                          const SizedBox(width: 8),
                          _buildFilterPill('Social', 'social'),
                          const SizedBox(width: 8),
                          _buildFilterPill('Cardápio', 'cardapio'),
                          const SizedBox(width: 8),
                          _buildFilterPill('LinkHub', 'linkhub'),
                          const SizedBox(width: 8),
                          _buildFilterPill('Outros', 'outro'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (templatesAsync.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.orangeAction),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161715),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(LucideIcons.layoutTemplate, size: 40, color: Color(0xFF6B7280)),
                              const SizedBox(height: 12),
                              Text(
                                allTemplates.isEmpty
                                    ? 'Nenhum modelo cadastrado ainda.\nCrie seu primeiro modelo de arte para placas.'
                                    : 'Nenhum modelo para a categoria selecionada.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF9E9E9E),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((tmpl) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTemplateCard(tmpl),
                          )),

                    const SizedBox(height: 20),

                    // Botão Novo Modelo
                    Material(
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => context.push('/templates/new'),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Novo modelo',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF2C2F2A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF10110F) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(PlateTemplate template) {
    return InkWell(
      onTap: () => context.push('/templates/${template.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF222421),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333532)),
              ),
              clipBehavior: Clip.antiAlias,
              child: template.baseImageUrl.isNotEmpty
                  ? Image.network(
                      template.baseImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, color: Colors.white54, size: 24),
                    )
                  : const Icon(LucideIcons.layoutTemplate, color: AppColors.orangeAction, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: template.isCanva
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                              : const Color(0xFF9E9E9E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: template.isCanva ? const Color(0xFF7C3AED) : const Color(0xFF6B7280),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          template.isCanva ? 'CANVA' : 'INTERNO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: template.isCanva ? const Color(0xFFA5ADEB) : Colors.white70,
                          ),
                        ),
                      ),
                      if (template.relatedServiceType != null && template.relatedServiceType!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.6), width: 0.8),
                          ),
                          child: Text(
                            template.relatedServiceType!.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${template.physicalWidthCm}x${template.physicalHeightCm} cm • ${template.category.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 14,
                        color: template.qrPlacements.isNotEmpty ? const Color(0xFF22C55E) : const Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        template.qrPlacements.isNotEmpty
                            ? '${template.qrPlacements.length} QR posicionado(s)'
                            : 'QR pendente de posição',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: template.qrPlacements.isNotEmpty ? const Color(0xFF22C55E) : const Color(0xFFFACC15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }
}
