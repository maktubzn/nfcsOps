import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/plate_template.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/url_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_editor_screen.dart';

/// Tela de Detalhe de um Modelo de Placa (Template).
/// Permite visualizar layout, abrir projeto no Canva, baixar QR codes transparentes em alta resolução,
/// baixar arte final para gráfica e vincular empresas a este modelo.
class TemplateDetailScreen extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends ConsumerState<TemplateDetailScreen> {
  Future<void> _editQrPlacement(PlateTemplate template) async {
    final placement = template.qrPlacements.firstOrNull;
    final isLocal = !template.baseImageUrl.startsWith('http');

    final result = await Navigator.of(context).push<QrPlacement>(
      MaterialPageRoute(
        builder: (_) => QrEditorScreen(
          imageUrl: isLocal ? null : template.baseImageUrl,
          localImagePath: isLocal ? template.baseImageUrl : null,
          physicalWidthCm: template.physicalWidthCm,
          physicalHeightCm: template.physicalHeightCm,
          initialPlacement: placement,
        ),
      ),
    );

    if (result != null) {
      final repo = ref.read(templateRepositoryProvider);
      final updated = template.copyWith(qrPlacements: [result]);
      await repo.updateTemplate(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posição do QR atualizada!'), backgroundColor: AppColors.greenSuccess),
      );
    }
  }

  Future<void> _deleteTemplate(PlateTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191A18),
        title: const Text('Excluir modelo?', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: Text('Deseja realmente remover o modelo "${template.name}"?', style: const TextStyle(color: Colors.white70, fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.redError)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(templateRepositoryProvider);
      await repo.deleteTemplate(template.id);
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _copyUrl(String url, String label) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link dinâmico ($label) copiado para a área de transferência!'),
        backgroundColor: AppColors.greenSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportTransparentQr(String data, String label) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final bytes = picData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_${label.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'QR Code Transparente em Alta Definição - $label');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar QR: $e'), backgroundColor: AppColors.redError),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesStreamProvider);
    final allTemplates = templatesAsync.value ?? [];
    final template = allTemplates.where((t) => t.id == widget.templateId).firstOrNull;

    if (template == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
        body: const Center(child: Text('Modelo não encontrado.', style: TextStyle(color: Colors.white70))),
      );
    }

    final placement = template.qrPlacements.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => _deleteTemplate(template),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visualização / Preview da Arte
              if (template.isCanva && (template.baseImageUrl.isEmpty || (!template.baseImageUrl.startsWith('http') && !File(template.baseImageUrl).existsSync()))) ...[
                // Banner elegante do Canva quando não há anexo local
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1730),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.palette, color: Color(0xFFA5ADEB), size: 28),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Design Gerenciado no Canva',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        template.page2ServiceType != null
                            ? 'Modelo com 2 Páginas / QR Codes Dinâmicos'
                            : 'Modelo com 1 Página / QR Code Dinâmico',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      if (template.canvaProjectUrl != null && template.canvaProjectUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Material(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => UrlLauncherService.openUrl(template.canvaProjectUrl!),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.externalLink, size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Abrir Projeto no Canva',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Placa Renderizada com QR sobreposto
                Center(
                  child: AspectRatio(
                    aspectRatio: template.physicalWidthCm / template.physicalHeightCm,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final canvasW = constraints.maxWidth;
                          final canvasH = constraints.maxHeight;

                          return Stack(
                            children: [
                              Positioned.fill(child: _buildImage(template.baseImageUrl)),
                              if (placement != null && !template.isCanva)
                                Positioned(
                                  left: placement.xPercent * canvasW,
                                  top: placement.yPercent * canvasH,
                                  width: placement.wPercent * canvasW,
                                  height: placement.hPercent * canvasH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.orangeAction, width: 2),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.qr_code_2, size: 28, color: Color(0xFF10110F)),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Metadados do Modelo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D1B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF282A26)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Origem', template.isCanva ? 'ARTE DO CANVA' : 'MODELO INTERNO',
                        valueColor: template.isCanva ? const Color(0xFFA5ADEB) : Colors.white),
                    const Divider(color: Color(0xFF282A26), height: 16),
                    _buildInfoRow('Categoria', template.category.toUpperCase()),
                    const Divider(color: Color(0xFF282A26), height: 16),
                    _buildInfoRow('Tipo Físico', template.productType.replaceAll('_', ' ').toUpperCase()),
                    const Divider(color: Color(0xFF282A26), height: 16),
                    _buildInfoRow('Dimensões Físicas', '${template.physicalWidthCm} x ${template.physicalHeightCm} cm'),
                    if (template.isCanva && template.page2ServiceType != null) ...[
                      const Divider(color: Color(0xFF282A26), height: 16),
                      _buildInfoRow('Estrutura', '2 PÁGINAS (FRENTE E VERSO)', valueColor: const Color(0xFF7DD3FC)),
                    ],
                  ],
                ),
              ),

              // Se for do Canva: Seção de QR Codes e Downloads
              if (template.isCanva) ...[
                const SizedBox(height: 20),
                const Text(
                  'Link do QR Code da Arte',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Link detectado da arte que este cartão/placa abre.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 12),

                // Card QR - Frente do Cartão
                _buildQrDownloadCard(
                  title: 'QR Code da Arte (${template.relatedServiceType ?? "Geral"})',
                  url: template.page1DynamicUrl ?? template.qrPlacements.firstOrNull?.dynamicUrl ?? 'https://instagram.com',
                  color: const Color(0xFF22C55E),
                ),

                if (template.canvaProjectUrl != null && template.canvaProjectUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Material(
                    color: const Color(0xFF1E1730),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => UrlLauncherService.openUrl(template.canvaProjectUrl!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.externalLink, color: Color(0xFFA5ADEB), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Abrir Projeto no Canva',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFA5ADEB)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              // Se for Modelo Interno: Ajustar QR
              if (!template.isCanva) ...[
                const SizedBox(height: 14),
                Material(
                  color: const Color(0xFF1E201D),
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    onTap: () => _editQrPlacement(template),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.move, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ajustar Posição do QR Code',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Botão Criar Placa para Empresa
              Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: () => context.push('/designs/generate?templateId=${template.id}'),
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.printer, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Vincular e Gerar Placa para Empresa',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrDownloadCard({
    required String title,
    required String url,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF191A18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 56,
              gapless: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (url.startsWith('http'))
                      InkWell(
                        onTap: () => UrlLauncherService.openUrl(url),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132216),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.externalLink, size: 12, color: Color(0xFF22C55E)),
                              SizedBox(width: 4),
                              Text('Testar', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                            ],
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: () => _copyUrl(url, title),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282A26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Copiar Link', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _exportTransparentQr(url, title),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.download, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text('Baixar PNG', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                          ],
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
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF9E9E9E))),
        Text(
          value,
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.image, color: Colors.white38, size: 40)),
      );
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.image, color: Colors.white38, size: 40)),
      );
    }
    return const Center(child: Icon(LucideIcons.image, color: Colors.white38, size: 40));
  }
}
