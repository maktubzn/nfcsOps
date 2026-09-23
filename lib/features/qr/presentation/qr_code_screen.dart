import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nfc_app_header.dart';

/// Tela S09 — QR Code para impressão e regravação NFC.
/// Renderiza QR Code real via qr_flutter em card creme com quiet zone generosa e ações completas de exportação.
class QrCodeScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const QrCodeScreen({super.key, required this.serviceId});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  int _renderKey = 0;

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

  Future<void> _handleDownloadPng(String url) async {
    try {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code pronto para uso!'),
            backgroundColor: AppColors.greenSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final painter = QrPainter(
        data: url,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF10110F),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF10110F),
        ),
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (picData == null) throw Exception('Falha ao rasterizar QR Code');

      final bytes = picData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/qr_${widget.serviceId}.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code PNG (1024x1024) salvo: ${file.path}'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar PNG: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDownloadSvg(String url) async {
    try {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vetor SVG pronto para uso!'),
            backgroundColor: AppColors.greenSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final qrValidationResult = QrValidator.validate(
        data: url,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      final qrCode = qrValidationResult.qrCode;
      if (qrCode == null) throw Exception('Falha ao codificar QR Code em vetor');

      final qrImage = QrImage(qrCode);
      final moduleCount = qrImage.moduleCount;
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $moduleCount $moduleCount" width="1024" height="1024">');
      buffer.writeln('<rect width="100%" height="100%" fill="#ffffff"/>');
      for (int x = 0; x < moduleCount; x++) {
        for (int y = 0; y < moduleCount; y++) {
          if (qrImage.isDark(y, x)) {
            buffer.writeln('<rect x="$x" y="$y" width="1" height="1" fill="#10110F"/>');
          }
        }
      }
      buffer.writeln('</svg>');

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/qr_${widget.serviceId}.svg');
      await file.writeAsString(buffer.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code vetorial SVG salvo: ${file.path}'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar SVG: $e'),
          backgroundColor: AppColors.redError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allServices = servicesAsync.value ?? [];
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
    final url = service.destinationUrl;
    final serviceTitle = service.publicTitle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
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

                    // Título e subtítulo
                    const Text(
                      'QR Code',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$companyName • $serviceTitle',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card Creme Grande com QR Code Real
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              key: ValueKey(_renderKey),
                              data: url,
                              version: QrVersions.auto,
                              size: 190.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF10110F),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF10110F),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'QR estático',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10110F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Destino para impressão',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Caixa do link com ícone de cópia (protegida contra overflow)
                          InkWell(
                            onTap: () => _handleCopyUrl(url),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 290),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E1D4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10110F),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.copy, size: 16, color: Color(0xFF10110F)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Prévia ilustrativa',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF8E918F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botão Laranja: "Baixar PNG"
                    Material(
                      color: AppColors.orangeAction,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => _handleDownloadPng(url),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.download, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Baixar PNG',
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

                    // Botão Secundário Dark: "Baixar SVG"
                    Material(
                      color: const Color(0xFF1E201D),
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        onTap: () => _handleDownloadSvg(url),
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.download, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Baixar SVG',
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

                    const SizedBox(height: 14),

                    // Linhas de Ações
                    _buildRow(
                      icon: LucideIcons.copy,
                      label: 'Copiar URL',
                      onTap: () => _handleCopyUrl(url),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      icon: LucideIcons.externalLink,
                      label: 'Abrir URL',
                      onTap: () => UrlLauncherService.openUrlWithFeedback(context, url),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      icon: LucideIcons.refreshCw,
                      label: 'Regenerar visual',
                      onTap: () {
                        setState(() => _renderKey++);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visual do QR Code regenerado.')),
                        );
                      },
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

  Widget _buildRow({required IconData icon, required String label, required VoidCallback onTap}) {
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
