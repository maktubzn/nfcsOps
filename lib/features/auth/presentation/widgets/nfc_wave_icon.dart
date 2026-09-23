import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Ícone vetorial estilizado de onda/sinal NFC (3 arcos radiantes) em laranja de ação.
class NfcWaveIcon extends StatelessWidget {
  final double? width;
  final double? height;
  final double size;
  final Color color;

  const NfcWaveIcon({
    super.key,
    this.width,
    this.height,
    this.size = 28.0,
    this.color = AppColors.orangeAction,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    return CustomPaint(
      size: Size(w, h),
      painter: _NfcWavePainter(color: color),
    );
  }
}

class _NfcWavePainter extends CustomPainter {
  final Color color;

  _NfcWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arco 1 (pequeno interno)
    paint.strokeWidth = w * 0.17;
    final rect1 = Rect.fromCenter(
      center: Offset(w * 0.08, h * 0.5),
      width: w * 0.55,
      height: h * 0.52,
    );
    canvas.drawArc(rect1, -1.0, 2.0, false, paint);

    // Arco 2 (médio intermediário)
    paint.strokeWidth = w * 0.16;
    final rect2 = Rect.fromCenter(
      center: Offset(w * 0.08, h * 0.5),
      width: w * 1.05,
      height: h * 0.82,
    );
    canvas.drawArc(rect2, -0.96, 1.92, false, paint);

    // Arco 3 (grande externo)
    paint.strokeWidth = w * 0.15;
    final rect3 = Rect.fromCenter(
      center: Offset(w * 0.08, h * 0.5),
      width: w * 1.55,
      height: h * 1.05,
    );
    canvas.drawArc(rect3, -0.92, 1.84, false, paint);
  }

  @override
  bool shouldRepaint(covariant _NfcWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
