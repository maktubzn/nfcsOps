import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/generated_design.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/url_launcher_service.dart';
import '../../../core/theme/app_colors.dart';

class DesignPreviewScreen extends ConsumerStatefulWidget {
  final String designId;

  const DesignPreviewScreen({super.key, required this.designId});

  @override
  ConsumerState<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends ConsumerState<DesignPreviewScreen> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportDesign(
    GeneratedDesign design,
    String shortCode, {
    dynamic template,
    dynamic company,
  }) async {
    setState(() => _isExporting = true);
    try {
      // Se for arte do Canva e o arquivo original existir localmente, compartilha diretamente a arte pura
      if (template != null && template.isCanva == true && !kIsWeb) {
        final rawPath = template.baseImageUrl as String?;
        if (rawPath != null && File(rawPath).existsSync()) {
          await Share.shareXFiles(
            [XFile(rawPath)],
            text: 'Arte final da Placa NFC Ops (Canva) - ${company?.tradeName ?? ''}',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arte limpa original do Canva exportada com sucesso!'), backgroundColor: AppColors.greenSuccess),
          );
          return;
        }
      }

      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Visualização não carregada');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Falha ao renderizar PNG');

      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arte gerada com sucesso!'), backgroundColor: AppColors.greenSuccess),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/placa_${shortCode}_${design.id}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Arte final da Placa NFC Ops - QR [$shortCode]',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arte exportada: $filePath'), backgroundColor: AppColors.greenSuccess),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar arte: $e'), backgroundColor: AppColors.redError),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final designsAsync = ref.watch(generatedDesignsStreamProvider);
    final templatesAsync = ref.watch(templatesStreamProvider);
    final qrCodesAsync = ref.watch(qrCodesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allDesigns = designsAsync.value ?? [];
    final allTemplates = templatesAsync.value ?? [];
    final allQrCodes = qrCodesAsync.value ?? [];
    final allCompanies = companiesAsync.value ?? [];

    final design = allDesigns.where((d) => d.id == widget.designId).firstOrNull;

    if (design == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
        body: const Center(child: Text('Arte não encontrada.', style: TextStyle(color: Colors.white70))),
      );
    }

    final template = allTemplates.where((t) => t.id == design.templateId).firstOrNull;
    final qrCode = allQrCodes.where((q) => q.id == design.qrCodeId).firstOrNull;
    final company = allCompanies.where((c) => c.id == design.companyId).firstOrNull;

    final shortCode = qrCode?.shortCode ?? 'NFC-QR';
    final placement = template?.qrPlacements.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/inventory'),
        ),
        title: const Text(
          'Prévia da Placa',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identificação da Empresa e QR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company?.tradeName ?? 'Empresa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${template?.name ?? 'Modelo'} • QR [$shortCode]',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('PRONTO', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Prévia renderizável da Arte
              Center(
                child: AspectRatio(
                  aspectRatio: (template?.physicalWidthCm ?? 10.0) / (template?.physicalHeightCm ?? 10.0),
                  child: RepaintBoundary(
                    key: _previewKey,
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

                          final xPercent = placement?.xPercent ?? 0.35;
                          final yPercent = placement?.yPercent ?? 0.35;
                          final wPercent = placement?.wPercent ?? 0.30;
                          final hPercent = placement?.hPercent ?? 0.30;

                          final qrPixelW = wPercent * canvasW;
                          final qrPixelH = hPercent * canvasH;

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: _buildTemplateImage(template?.baseImageUrl ?? ''),
                              ),
                              if (template?.isCanva != true && qrCode != null)
                                Positioned(
                                  left: xPercent * canvasW,
                                  top: yPercent * canvasH,
                                  width: qrPixelW,
                                  height: qrPixelH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(qrPixelW * 0.05),
                                    child: QrImageView(
                                      data: qrCode.publicUrl,
                                      version: QrVersions.auto,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF10110F)),
                                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF10110F)),
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
              ),

              const SizedBox(height: 20),

              // Botão Exportar PNG
              Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: _isExporting ? null : () => _exportDesign(design, shortCode, template: template, company: company),
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: _isExporting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.download, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Exportar PNG para Impressão',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botões Secundários
              if (qrCode != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF333532)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => UrlLauncherService.openUrlWithFeedback(context, qrCode.currentDestination),
                        icon: const Icon(LucideIcons.externalLink, size: 16),
                        label: const Text('Testar QR', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF333532)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => context.push('/qr-codes/${qrCode.id}'),
                        icon: const Icon(LucideIcons.settings2, size: 16),
                        label: const Text('Editar Destino', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Card de Informações Técnicas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D1B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF282A26)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Link Permanente', qrCode?.publicUrl ?? '—'),
                    const Divider(color: Color(0xFF282A26), height: 16),
                    _buildInfoRow('Destino Atual', qrCode?.currentDestination ?? '—'),
                    const Divider(color: Color(0xFF282A26), height: 16),
                    _buildInfoRow('Dimensões Físicas', '${template?.physicalWidthCm ?? 10} x ${template?.physicalHeightCm ?? 10} cm'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E201D),
      child: const Center(
        child: Icon(LucideIcons.image, size: 40, color: Colors.white38),
      ),
    );
  }
}
