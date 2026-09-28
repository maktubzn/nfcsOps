import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/plate_template.dart';
import '../../../core/theme/app_colors.dart';

class QrEditorScreen extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double physicalWidthCm;
  final double physicalHeightCm;
  final QrPlacement? initialPlacement;

  const QrEditorScreen({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.physicalWidthCm = 10.0,
    this.physicalHeightCm = 10.0,
    this.initialPlacement,
  });

  @override
  State<QrEditorScreen> createState() => _QrEditorScreenState();
}

class _QrEditorScreenState extends State<QrEditorScreen> {
  late double _xPercent;
  late double _yPercent;
  late double _sizePercent;

  @override
  void initState() {
    super.initState();
    _xPercent = widget.initialPlacement?.xPercent ?? 0.35;
    _yPercent = widget.initialPlacement?.yPercent ?? 0.35;
    _sizePercent = widget.initialPlacement?.wPercent ?? 0.30;
  }

  void _confirm() {
    final placement = QrPlacement(
      id: widget.initialPlacement?.id ?? 'qrp-${DateTime.now().millisecondsSinceEpoch}',
      label: 'QR Principal',
      xPercent: _xPercent,
      yPercent: _yPercent,
      wPercent: _sizePercent,
      hPercent: _sizePercent,
    );
    context.pop(placement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Posicionar QR Code',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text(
              'Confirmar',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppColors.orangeAction,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF191A18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'X: ${(_xPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
                  ),
                  Text(
                    'Y: ${(_yPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
                  ),
                  Text(
                    'Tam: ${(_sizePercent * widget.physicalWidthCm).toStringAsFixed(1)} cm',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.orangeAction, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Área de edição visual
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: widget.physicalWidthCm / widget.physicalHeightCm,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasW = constraints.maxWidth;
                        final canvasH = constraints.maxHeight;
                        final qrPixelSize = _sizePercent * canvasW;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF222421),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF333532)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Imagem base do template
                              Positioned.fill(
                                child: _buildBaseImage(),
                              ),

                              // Caixa do QR arrastável
                              Positioned(
                                left: _xPercent * canvasW,
                                top: _yPercent * canvasH,
                                width: qrPixelSize,
                                height: qrPixelSize,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _xPercent += details.delta.dx / canvasW;
                                      _yPercent += details.delta.dy / canvasH;
                                      _xPercent = _xPercent.clamp(0.0, 1.0 - _sizePercent);
                                      _yPercent = _yPercent.clamp(0.0, 1.0 - _sizePercent);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.orangeAction, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(Icons.qr_code_2, size: 36, color: Color(0xFF10110F)),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppColors.orangeAction,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(LucideIcons.move, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Controles de tamanho na parte inferior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF191A18),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tamanho do QR Code',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        '${(_sizePercent * 100).toInt()}% da placa',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.orangeAction, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sizePercent,
                    min: 0.10,
                    max: 0.60,
                    divisions: 50,
                    activeColor: AppColors.orangeAction,
                    inactiveColor: const Color(0xFF333532),
                    onChanged: (v) {
                      setState(() {
                        _sizePercent = v;
                        _xPercent = _xPercent.clamp(0.0, 1.0 - _sizePercent);
                        _yPercent = _yPercent.clamp(0.0, 1.0 - _sizePercent);
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Arraste o quadrado branco para posicionar o QR Code exatamente onde ele deve aparecer na placa impressa.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.orangeAction,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _confirm,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: const Text(
                          'Salvar Posição do QR',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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
    );
  }

  Widget _buildBaseImage() {
    if (widget.localImagePath != null && widget.localImagePath!.isNotEmpty && !kIsWeb) {
      return Image.file(
        File(widget.localImagePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 48, color: Colors.white38),
            SizedBox(height: 8),
            Text(
              'Prévia da Placa',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
